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

require 'rmt/ssl/certificate_generator'

Yast.import 'Report'

describe RMT::SSL::CertificateGenerator do
  subject(:generator) { described_class.new }

  let(:ssl_files) do
    described_class::OPENSSL_FILES.map { |id, filename| [id, File.join(described_class::RMT_SSL_DIR, filename)] }.to_h
  end

  let(:ca_files) { %i[ca_private_key ca_certificate] }
  let(:server_cert_files) { %i[server_private_key server_certificate] }
  let(:crt_and_key_files) { ca_files + server_cert_files }

  describe '#ca_present?' do
    subject(:result) { generator.ca_present? }

    before do
      # Yast reads locale data at startup for i18n
      expect(File).to receive(:exist?).with('/usr/share/YaST2/locale').and_return(false)
    end

    it 'returns false when none of the files exist' do
      ca_files.each do |file|
        expect(File).to receive(:exist?).with(ssl_files[file]).and_return(false)
      end
      expect(result).to eq(false)
    end

    it 'returns false when all of the files are empty' do
      ca_files.each do |file|
        expect(File).to receive(:exist?).with(ssl_files[file]).and_return(true)
        expect(File).to receive(:zero?).with(ssl_files[file]).and_return(true)
      end
      expect(result).to eq(false)
    end

    it 'returns true when one the files exist and is not empty' do
      file = ca_files.shift
      expect(File).to receive(:exist?).with(ssl_files[file]).and_return(true)
      expect(File).to receive(:zero?).with(ssl_files[file]).and_return(false)

      expect(result).to eq(true)
    end
  end

  describe '#ca_encrypted?' do
    subject(:method_call) { generator.ca_encrypted? }

    it 'calls #valid_password? method' do
      expect(generator).to receive(:valid_password?).with(' ')
      method_call
    end
  end

  describe '#valid_password?' do
    subject(:method_call) { generator.valid_password?(password) }

    let(:password) { 'foobar' }

    context 'with valid password' do
      it 'returns true' do
        expect_any_instance_of(Cheetah::DefaultRecorder).not_to receive(:record_stdin)
        expect(RMT::Execute).to receive(:on_target!).with(
          'openssl', 'rsa', '-passin', 'stdin', '-in', ssl_files[:ca_private_key],
          stdin: password,
          logger: nil
        ).and_return(true)
        expect(method_call).to eq(true)
      end
    end

    context 'with invalid password' do
      it 'returns false' do
        expect_any_instance_of(Cheetah::DefaultRecorder).not_to receive(:record_stdin)
        expect(RMT::Execute).to receive(:on_target!).with(
          'openssl', 'rsa', '-passin', 'stdin', '-in', ssl_files[:ca_private_key],
          stdin: password,
          logger: nil
        ).and_raise(Cheetah::ExecutionFailed.new('', '', '', ''))
        expect(method_call).to eq(false)
      end
    end
  end

  describe '#server_cert_present??' do
    subject(:result) { generator.server_cert_present? }

    before do
      # Yast reads locale data at startup for i18n
      expect(File).to receive(:exist?).with('/usr/share/YaST2/locale').and_return(false)
    end

    it 'returns false when none of the files exist' do
      server_cert_files.each do |file|
        expect(File).to receive(:exist?).with(ssl_files[file]).and_return(false)
      end
      expect(result).to eq(false)
    end

    it 'returns false when all of the files are empty' do
      server_cert_files.each do |file|
        expect(File).to receive(:exist?).with(ssl_files[file]).and_return(true)
        expect(File).to receive(:zero?).with(ssl_files[file]).and_return(true)
      end
      expect(result).to eq(false)
    end

    it 'returns true when one the files exist and is not empty' do
      file = server_cert_files.shift
      expect(File).to receive(:exist?).with(ssl_files[file]).and_return(true)
      expect(File).to receive(:zero?).with(ssl_files[file]).and_return(false)

      expect(result).to eq(true)
    end
  end

  describe '#generate' do
    let(:scr_path) { Yast.path('.target.string') }
    let(:config_generator_double) { instance_double(RMT::SSL::ConfigGenerator) }
    let(:ca_config) { 'ca_config' }
    let(:server_config) { 'server_config' }
    let(:ca_cert) { 'ca_cert' }
    let(:server_cert) { 'server_cert' }
    let(:common_name) { 'example.org' }
    let(:alt_names) { ['foo.example.org', 'bar.example.org'] }
    let(:ca_password) { 'foobar' }

    context 'when CA is not yet generated' do
      it 'generates the CA and server certificates' do
        expect(RMT::SSL::ConfigGenerator).to receive(:new).and_return(config_generator_double)
        expect(generator).to receive(:ca_present?).and_return(false).exactly(2).times
        expect(config_generator_double).to receive(:make_ca_config).and_return(ca_config)
        expect(config_generator_double).to receive(:make_server_config).and_return(server_config)

        expect(generator).to receive(:create_files)

        expect(Yast::SCR).to receive(:Write).with(scr_path, ssl_files[:ca_serial_file], '01')
        expect(Yast::SCR).to receive(:Write).with(scr_path, ssl_files[:ca_config], ca_config)
        expect(Yast::SCR).to receive(:Write).with(scr_path, ssl_files[:server_config], server_config)

        expect_any_instance_of(Cheetah::DefaultRecorder).not_to receive(:record_stdin)
        expect(RMT::Execute).to receive(:on_target!).with(
          'openssl', 'genrsa', '-aes256', '-passout', 'stdin', '-out',
          ssl_files[:ca_private_key], described_class::OPENSSL_KEY_BITS,
          stdin: ca_password,
          logger: nil
        )

        expect(RMT::Execute).to receive(:on_target!).with(
          'openssl', 'genrsa', '-out',
          ssl_files[:server_private_key], described_class::OPENSSL_KEY_BITS
        )

        expect(RMT::Execute).to receive(:on_target!).with(
          'openssl', 'req', '-x509', '-new', '-nodes',
          '-key', ssl_files[:ca_private_key], '-sha256', '-days', described_class::OPENSSL_CA_VALIDITY_DAYS,
          '-out', ssl_files[:ca_certificate], '-passin', 'stdin', '-config', ssl_files[:ca_config],
          stdin: ca_password,
          logger: nil
        )

        expect(RMT::Execute).to receive(:on_target!).with(
          'openssl', 'req', '-new', '-key', ssl_files[:server_private_key],
          '-out', ssl_files[:server_csr], '-config', ssl_files[:server_config]
        )

        expect(RMT::Execute).to receive(:on_target!).with(
          'openssl', 'x509', '-req', '-in', ssl_files[:server_csr],
          '-out', ssl_files[:server_certificate], '-CA', ssl_files[:ca_certificate],
          '-CAkey', ssl_files[:ca_private_key], '-passin', 'stdin', '-days', described_class::OPENSSL_SERVER_CERT_VALIDITY_DAYS,
          '-sha256', '-CAcreateserial', '-extensions', 'v3_server_sign',
          '-extfile', ssl_files[:server_config],
          stdin: ca_password,
          logger: nil
        )

        expect(Yast::SCR).to receive(:Read).with(scr_path, ssl_files[:server_certificate]).and_return(server_cert)
        expect(Yast::SCR).to receive(:Read).with(scr_path, ssl_files[:ca_certificate]).and_return(ca_cert)
        expect(Yast::SCR).to receive(:Write).with(scr_path, ssl_files[:server_certificate], server_cert + ca_cert)

        expect(RMT::Execute).to receive(:on_target!).with('chown', 'root:nginx', ssl_files[:ca_certificate])
        expect(RMT::Execute).to receive(:on_target!).with('chmod', '0640', ssl_files[:ca_certificate])

        generator.generate(common_name, alt_names, ca_password)
      end
    end

    context 'when CA is generated without password' do
      let(:ca_password) { '' }

      it 'generates only the server certificate' do
        expect(RMT::SSL::ConfigGenerator).to receive(:new).and_return(config_generator_double)
        expect(generator).to receive(:ca_present?).and_return(true).exactly(2).times
        expect(config_generator_double).to receive(:make_server_config).and_return(server_config)

        expect(generator).to receive(:create_files)

        expect(Yast::SCR).to receive(:Write).with(scr_path, ssl_files[:server_config], server_config)

        expect(RMT::Execute).to receive(:on_target!).with(
          'openssl', 'genrsa', '-out',
          ssl_files[:server_private_key], described_class::OPENSSL_KEY_BITS
        )

        expect(RMT::Execute).to receive(:on_target!).with(
          'openssl', 'req', '-new', '-key', ssl_files[:server_private_key],
          '-out', ssl_files[:server_csr], '-config', ssl_files[:server_config]
        )

        expect(RMT::Execute).to receive(:on_target!).with(
          'openssl', 'x509', '-req', '-in', ssl_files[:server_csr],
          '-out', ssl_files[:server_certificate], '-CA', ssl_files[:ca_certificate],
          '-CAkey', ssl_files[:ca_private_key], '-days', described_class::OPENSSL_SERVER_CERT_VALIDITY_DAYS,
          '-sha256', '-CAcreateserial', '-extensions', 'v3_server_sign',
          '-extfile', ssl_files[:server_config]
        )

        expect(Yast::SCR).to receive(:Read).with(scr_path, ssl_files[:server_certificate]).and_return(server_cert)
        expect(Yast::SCR).to receive(:Read).with(scr_path, ssl_files[:ca_certificate]).and_return(ca_cert)
        expect(Yast::SCR).to receive(:Write).with(scr_path, ssl_files[:server_certificate], server_cert + ca_cert)

        expect(RMT::Execute).to receive(:on_target!).with('chown', 'root:nginx', ssl_files[:ca_certificate])
        expect(RMT::Execute).to receive(:on_target!).with('chmod', '0640', ssl_files[:ca_certificate])

        generator.generate(common_name, alt_names, ca_password)
      end
    end

    context 'when CA is already present' do
      it 'generates only the server certificate' do
        expect(RMT::SSL::ConfigGenerator).to receive(:new).and_return(config_generator_double)
        expect(generator).to receive(:ca_present?).and_return(true).exactly(2).times
        expect(config_generator_double).to receive(:make_server_config).and_return(server_config)

        expect(generator).to receive(:create_files)

        expect(Yast::SCR).to receive(:Write).with(scr_path, ssl_files[:server_config], server_config)

        expect(RMT::Execute).to receive(:on_target!).with(
          'openssl', 'genrsa', '-out',
          ssl_files[:server_private_key], described_class::OPENSSL_KEY_BITS
        )

        expect(RMT::Execute).to receive(:on_target!).with(
          'openssl', 'req', '-new', '-key', ssl_files[:server_private_key],
          '-out', ssl_files[:server_csr], '-config', ssl_files[:server_config]
        )

        expect_any_instance_of(Cheetah::DefaultRecorder).not_to receive(:record_stdin)
        expect(RMT::Execute).to receive(:on_target!).with(
          'openssl', 'x509', '-req', '-in', ssl_files[:server_csr],
          '-out', ssl_files[:server_certificate], '-CA', ssl_files[:ca_certificate],
          '-CAkey', ssl_files[:ca_private_key], '-passin', 'stdin', '-days', described_class::OPENSSL_SERVER_CERT_VALIDITY_DAYS,
          '-sha256', '-CAcreateserial', '-extensions', 'v3_server_sign',
          '-extfile', ssl_files[:server_config],
          stdin: ca_password,
          logger: nil
        )

        expect(Yast::SCR).to receive(:Read).with(scr_path, ssl_files[:server_certificate]).and_return(server_cert)
        expect(Yast::SCR).to receive(:Read).with(scr_path, ssl_files[:ca_certificate]).and_return(ca_cert)
        expect(Yast::SCR).to receive(:Write).with(scr_path, ssl_files[:server_certificate], server_cert + ca_cert)

        expect(RMT::Execute).to receive(:on_target!).with('chown', 'root:nginx', ssl_files[:ca_certificate])
        expect(RMT::Execute).to receive(:on_target!).with('chmod', '0640', ssl_files[:ca_certificate])

        generator.generate(common_name, alt_names, ca_password)
      end
    end

    it 'handles Cheetah::ExecutionFailed exceptions' do
      expect(RMT::SSL::ConfigGenerator).to receive(:new).and_raise(Cheetah::ExecutionFailed.new('cmd', 1, '', 'Dummy error'))
      expect(Yast::Report).to receive(:Error).with("An error occurred during SSL certificate generation:\nDummy error\n")
      generator.generate(common_name, alt_names, ca_password)
    end

    it 'handles RMT::SSL::Exception exceptions' do
      expect(RMT::SSL::ConfigGenerator).to receive(:new).and_raise(RMT::SSL::Exception.new('Dummy error'))
      expect(Yast::Report).to receive(:Error).with("An error occurred during SSL certificate generation:\nDummy error\n")
      generator.generate(common_name, alt_names, ca_password)
    end
  end

  describe '#create_files' do
    it 'creates empty files for openssl and sets permissions' do
      ssl_files.each_value do |file|
        expect(generator).to receive(:write_file).with(file, '')
        expect(RMT::Execute).to receive(:on_target!).with('chmod', '0600', file)
      end
      generator.send(:create_files, ssl_files)
    end
  end

  describe '#write_file' do
    let(:filename) { '/tmp/test' }
    let(:content) { 'test' }

    it 'writes a file' do
      expect(Yast::SCR).to receive(:Write).with(Yast.path('.target.string'), filename, content).and_return(true)
      generator.send(:write_file, filename, content)
    end

    it 'raises and exception when write failed' do
      expect(Yast::SCR).to receive(:Write).with(Yast.path('.target.string'), filename, content).and_return(false)
      expect { generator.send(:write_file, filename, content) }.to raise_error(RMT::SSL::Exception, "Error writing file '#{filename}'")
    end
  end
end
