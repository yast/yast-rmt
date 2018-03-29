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

module RMT; end
module RMT::SSL; end

class RMT::SSL::Exception < RuntimeError; end

class RMT::SSL::CertificateGenerator
  RMT_SSL_DIR = '/usr/share/rmt/ssl/'.freeze

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

  def check_certs_presence
    %i[ca_private_key ca_certificate server_private_key server_certificate].each do |file_type|
      return true if File.exist?(@ssl_paths[file_type]) && !File.zero?(@ssl_paths[file_type])
    end

    false
  end

  def generate(common_name, alt_names)
    alt_names.unshift(common_name) unless alt_names.include?(common_name)
    config_generator = RMT::SSL::ConfigGenerator.new(common_name, alt_names)

    create_files

    Yast::SCR.Write(Yast.path('.target.string'), @ssl_paths[:ca_serial_file], '01')
    Yast::SCR.Write(Yast.path('.target.string'), @ssl_paths[:ca_config], config_generator.make_ca_config)
    Yast::SCR.Write(Yast.path('.target.string'), @ssl_paths[:server_config], config_generator.make_server_config)

    RMT::Execute.on_target!('openssl', 'genrsa', '-out', @ssl_paths[:ca_private_key], OPENSSL_KEY_BITS)
    RMT::Execute.on_target!('openssl', 'genrsa', '-out', @ssl_paths[:server_private_key], OPENSSL_KEY_BITS)

    RMT::Execute.on_target!(
      'openssl', 'req', '-x509', '-new', '-nodes', '-key', @ssl_paths[:ca_private_key],
      '-sha256', '-days', OPENSSL_CA_VALIDITY_DAYS, '-out', @ssl_paths[:ca_certificate],
      '-config', @ssl_paths[:ca_config]
    )

    RMT::Execute.on_target!(
      'openssl', 'req', '-new', '-key', @ssl_paths[:server_private_key],
      '-out', @ssl_paths[:server_csr], '-config', @ssl_paths[:server_config]
    )

    RMT::Execute.on_target!(
      'openssl', 'x509', '-req', '-in', @ssl_paths[:server_csr], '-out', @ssl_paths[:server_certificate],
      '-CA', @ssl_paths[:ca_certificate], '-CAkey', @ssl_paths[:ca_private_key],
      '-days', OPENSSL_SERVER_CERT_VALIDITY_DAYS, '-sha256',
      '-CAcreateserial',
      '-extensions', 'v3_server_sign', '-extfile', @ssl_paths[:server_config]
    )

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
      _("An error ocurred during SSL certificate generation:\n%<error>s\n") % { error: e.to_s }
    )
  end

  protected

  # Creates empty files and sets 600 permissions
  def create_files
    @ssl_paths.each_value do |file|
      write_file(file, '')
      RMT::Execute.on_target!('chmod', '0600', file)
    end
  end

  def write_file(filename, content)
    result = Yast::SCR.Write(Yast.path('.target.string'), filename, content)
    raise RMT::SSL::Exception, "Failed to write file #{filename}" unless result
  end
end
