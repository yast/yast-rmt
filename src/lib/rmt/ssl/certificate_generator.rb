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

class RMT::SSL::CertificateGenerator
  OPENSSL_FILES = {
    ca_config: 'rmt-ca.cnf',
    ca_private_key: 'rmt-ca.key',
    ca_certificate: 'rmt-ca.pem',
    server_config: 'rmt-server.cnf',
    server_private_key: 'rmt-server.key',
    server_certificate: 'rmt-server.pem',
    server_csr: 'rmt-server.csr'
  }.freeze

  OPENSSL_KEY_BITS = 2048
  OPENSSL_CA_VALIDITY_DAYS = 1024
  OPENSSL_SERVER_CERT_VALIDITY_DAYS = 1024

  def generate(temp_files)
    RMT::Execute.on_target!('openssl', 'genrsa', '-out', temp_files[:ca_private_key], OPENSSL_KEY_BITS)
    RMT::Execute.on_target!('openssl', 'genrsa', '-out', temp_files[:server_private_key], OPENSSL_KEY_BITS)

    # FIXME: needs some sort of error handling
    # FIXME: handle serial file too

    RMT::Execute.on_target!(
      'openssl', 'req', '-x509', '-new', '-nodes', '-key', temp_files[:ca_private_key],
      '-sha256', '-days', OPENSSL_CA_VALIDITY_DAYS, '-out', temp_files[:ca_certificate],
      '-config', temp_files[:ca_config]
    )

    RMT::Execute.on_target!(
      'openssl', 'req', '-new', '-key', temp_files[:server_private_key],
      '-out', temp_files[:server_csr], '-config', temp_files[:server_config]
    )

    RMT::Execute.on_target!(
      'openssl', 'x509', '-req', '-in', temp_files[:server_csr], '-out', temp_files[:server_certificate],
      '-CA', temp_files[:ca_certificate], '-CAkey', temp_files[:ca_private_key],
      '-days', OPENSSL_SERVER_CERT_VALIDITY_DAYS, '-sha256', '-CAcreateserial',
      '-extensions', 'v3_server_sign', '-extfile', temp_files[:server_config]
    )
  end

  # FIXME: needs error handling
  def touch_the_files(files)
    files.each do |file|
      Yast::SCR.Write(Yast.path('.target.string'), file, '')
      Yast::SCR.Execute(
        Yast.path('.target.bash'),
        Yast::Builtins.sformat("chmod 0600 '%1'", Yast::String.Quote(file))
      )
    end
  end
end
