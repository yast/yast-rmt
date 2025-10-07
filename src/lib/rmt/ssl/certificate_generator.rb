# Copyright (c) 2018 SUSE LLC.
#  All Rights Reserved.

#  This program is free software; you can redistribute it and/or
#  modify it under the terms of version 2 or 3 of the GNU General
#  Public License as published by the Free Software Foundation.

#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.   See the
#  GNU General Public License for more details.

#  You should have received a copy of the GNU General Public License
#  along with this program; if not, contact SUSE LLC.

#  To contact SUSE about this file by physical or electronic mail,
#  you may find current contact information at www.suse.com

require 'erb'
require 'resolv'
require 'rmt/execute'
require 'rmt/ssl/config_generator'

module RMT; end
module RMT::SSL; end

class RMT::SSL::Exception < RuntimeError; end

class RMT::SSL::CertificateGenerator
  RMT_SSL_DIR = '/etc/rmt/ssl/'.freeze

  OPENSSL_FILES = {
    ca_config: 'rmt-ca.cnf',
    ca_private_key: 'rmt-ca.key',
    ca_certificate: 'rmt-ca.crt',
    ca_serial_file: 'rmt-ca.srl',
    server_config: 'rmt-server.cnf',
    server_private_key: 'rmt-server.key',
    server_certificate: 'rmt-server.crt',
    server_csr: 'rmt-server.csr'
  }.freeze

  OPENSSL_KEY_BITS = 2048
  OPENSSL_CA_VALIDITY_DAYS = 1825
  OPENSSL_SERVER_CERT_VALIDITY_DAYS = 1825

  def initialize
    extend Yast::I18n
    textdomain 'rmt'

    @ssl_paths = OPENSSL_FILES.map { |id, filename| [id, File.join(RMT_SSL_DIR, filename)] }.to_h
  end

  def ca_present?
    %i[ca_private_key ca_certificate].each do |file_type|
      return true if File.exist?(@ssl_paths[file_type]) && !File.zero?(@ssl_paths[file_type])
    end
    false
  end

  def ca_encrypted?
    !valid_password?(' ') # check with emtpy password. password has one char otherwise command requires input
  end

  def valid_password?(password)
    RMT::Execute.on_target!(
      'openssl', 'rsa', '-passin', 'stdin', '-in', @ssl_paths[:ca_private_key],
      stdin: password,
      logger: nil # do not log in order to securely pass password
    )
    true
  rescue Cheetah::ExecutionFailed
    false
  end

  def server_cert_present?
    # NB this doesn't check the second file if the first one exists
    # An improvement would be to look for the absence of any ssl configuration and proceed in that case,
    # but leave ssl alone if any configuration (hand-edited or incomplete) is found
    %i[server_private_key server_certificate].each do |file_type|
      return true if File.exist?(@ssl_paths[file_type]) && !File.zero?(@ssl_paths[file_type])
    end
    false
  end

  # rubocop:disable Metrics/MethodLength
  def generate(common_name, alt_names, ca_password)
    config_generator = RMT::SSL::ConfigGenerator.new(common_name, alt_names)

    files = @ssl_paths.dup
    %i[ca_certificate ca_private_key ca_serial_file ca_config].each { |file| files.delete(file) } if ca_present?

    create_files(files)

    Yast::SCR.Write(Yast.path('.target.string'), @ssl_paths[:server_config], config_generator.make_server_config)
    unless ca_present?
      Yast::SCR.Write(Yast.path('.target.string'), @ssl_paths[:ca_serial_file], '01')
      Yast::SCR.Write(Yast.path('.target.string'), @ssl_paths[:ca_config], config_generator.make_ca_config)

      RMT::Execute.on_target!(
        'openssl', 'genrsa', '-aes256', '-out', @ssl_paths[:ca_private_key], '-pkeyopt', "rsa_keygen_bits:#{OPENSSL_KEY_BITS}",
        stdin: ca_password,
        logger: nil # do not log in order to securely pass password
      )
      RMT::Execute.on_target!(
        'openssl', 'req', '-x509', '-new', '-nodes', '-key', @ssl_paths[:ca_private_key],
        '-sha256', '-days', OPENSSL_CA_VALIDITY_DAYS, '-out', @ssl_paths[:ca_certificate],
        '-passin', 'stdin', '-config', @ssl_paths[:ca_config],
        stdin: ca_password,
        logger: nil # do not log in order to securely pass password
      )
    end

    RMT::Execute.on_target!('openssl', 'genrsa', '-out', @ssl_paths[:server_private_key], OPENSSL_KEY_BITS)
    RMT::Execute.on_target!(
      'openssl', 'req', '-new', '-key', @ssl_paths[:server_private_key],
      '-out', @ssl_paths[:server_csr], '-config', @ssl_paths[:server_config]
    )

    if !ca_password.empty?
      RMT::Execute.on_target!(
        'openssl', 'x509', '-req', '-in', @ssl_paths[:server_csr], '-out', @ssl_paths[:server_certificate],
        '-CA', @ssl_paths[:ca_certificate], '-CAkey', @ssl_paths[:ca_private_key],
        '-passin', 'stdin', '-days', OPENSSL_SERVER_CERT_VALIDITY_DAYS, '-sha256',
        '-CAcreateserial', '-extensions', 'v3_server_sign', '-extfile', @ssl_paths[:server_config],
        stdin: ca_password,
        logger: nil # do not log in order to securely pass password
      )
    else
      RMT::Execute.on_target!(
        'openssl', 'x509', '-req', '-in', @ssl_paths[:server_csr], '-out', @ssl_paths[:server_certificate],
        '-CA', @ssl_paths[:ca_certificate], '-CAkey', @ssl_paths[:ca_private_key],
        '-days', OPENSSL_SERVER_CERT_VALIDITY_DAYS, '-sha256',
        '-CAcreateserial', '-extensions', 'v3_server_sign', '-extfile', @ssl_paths[:server_config]
      )
    end

    # create certificates bundle
    server_cert = Yast::SCR.Read(Yast.path('.target.string'), @ssl_paths[:server_certificate])
    ca_cert = Yast::SCR.Read(Yast.path('.target.string'), @ssl_paths[:ca_certificate])
    Yast::SCR.Write(Yast.path('.target.string'), @ssl_paths[:server_certificate], server_cert + ca_cert)

    # change permissions so that clients can download CA certificate
    RMT::Execute.on_target!('chown', 'root:nginx', @ssl_paths[:ca_certificate])
    RMT::Execute.on_target!('chmod', '0640', @ssl_paths[:ca_certificate])
  rescue Cheetah::ExecutionFailed, RMT::SSL::Exception => e
    Yast.import 'Report'
    Yast::Report.Error(
      _("An error occurred during SSL certificate generation:\n%{error}\n") % {
        error: (e.class == Cheetah::ExecutionFailed) ? e.stderr : e.to_s
      }
    )
  end
  # rubocop:enable Metrics/MethodLength

  protected

  # Creates empty files and sets 600 permissions
  def create_files(files)
    files.each_value do |file|
      write_file(file, '')
      RMT::Execute.on_target!('chmod', '0600', file)
    end
  end

  def write_file(filename, content)
    return if Yast::SCR.Write(Yast.path('.target.string'), filename, content)

    Yast.import 'Message'
    raise RMT::SSL::Exception, Yast::Message.ErrorWritingFile(filename)
  end
end
