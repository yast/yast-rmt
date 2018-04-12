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

require 'rmt/ssl/config_generator'

describe RMT::SSL::ConfigGenerator do
  subject(:generator) { described_class.new(common_name, alt_names) }

  let(:common_name) { 'example.org' }
  let(:dns_names) { ['foo.example.org', 'bar.example.org'] }
  let(:ip_addresses) { ['1.1.1.1', '1111:2222:3333:4444:5555:6666:7777:8888'] }
  let(:alt_names) { dns_names + ip_addresses }
  let(:template_system_location) { File.join('/usr/share/YaST2/data/rmt', template_filename) }
  let(:template) { File.read(File.join('src/data/rmt', template_filename)) }

  describe '#new' do
    it 'matches DNS names' do
      expect(generator.dns_alt_names).to eq([common_name] + dns_names)
    end

    it 'matches IP addresses' do
      expect(generator.ip_alt_names).to eq(ip_addresses)
    end
  end

  describe '#make_ca_config' do
    let(:template_filename) { 'rmt-ca.cnf.erb' }

    it 'contains correct common name' do
      expect(File).to receive(:read).with(template_system_location).and_return(template)
      expect(generator.make_ca_config).to match(/CN\s*=\s*RMT Certificate Authority \(#{common_name}\)/)
    end

    it 'writes to correct file' do
      expect(File).to receive(:read).with(template_system_location).and_return(template)
      generator.make_ca_config
    end
  end

  describe '#make_server_config' do
    subject(:config) { generator.make_server_config }

    let(:template_filename) { 'rmt-server-cert.cnf.erb' }

    it 'contains correct common name' do
      expect(File).to receive(:read).with(template_system_location).and_return(template)
      expect(config).to match(/CN\s*=\s*#{common_name}/)
    end

    it 'contains DNS alternative common names' do
      expect(File).to receive(:read).with(template_system_location).and_return(template)
      dns_names.each do |alt_name|
        expect(config).to match(/DNS\.\d+\s*=\s*#{alt_name}/)
      end
    end

    it 'contains IP alternative common names' do
      expect(File).to receive(:read).with(template_system_location).and_return(template)
      ip_addresses.each do |alt_name|
        expect(config).to match(/IP\.\d+\s*=\s*#{alt_name}/)
      end
    end
  end
end
