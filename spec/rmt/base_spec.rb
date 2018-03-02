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

require 'rmt/base'

Yast.import 'Report'

describe RMT::Base do
  describe '.read_config_file' do
    let(:raw_data) { '{}' }

    it 'loads YAML and populates with default values' do
      expect(Yast::SCR).to receive(:Read).with(Yast.path('.target.string'), RMT::Base::CONFIG_FILENAME).and_return(raw_data)
      expect(YAML).to receive(:safe_load).with(raw_data).and_return({})
      expect(described_class.read_config_file).to include('scc', 'database')
    end

    it 'handles exceptions' do
      expect(Yast::SCR).to receive(:Read).with(Yast.path('.target.string'), RMT::Base::CONFIG_FILENAME).and_return(raw_data)
      expect(YAML).to receive(:safe_load).with(raw_data).and_raise('Yast load error')
      expect(described_class.read_config_file).to include('scc', 'database')
    end
  end

  describe '.write_config_file' do
    let(:config) { { 'scc' => { 'username' => 'user_mcuserface', 'password' => 'password' } } }

    it 'displays success message on success' do
      expect(Yast::SCR).to receive(:Write).with(
        Yast.path('.target.string'),
        RMT::Base::CONFIG_FILENAME,
        YAML.dump(config)
      ).and_return(true)

      expect(Yast::Popup).to receive(:Message).with('Configuration written successfully')

      described_class.write_config_file(config)
    end

    it 'reports error message on error' do
      expect(Yast::SCR).to receive(:Write).with(
        Yast.path('.target.string'),
        RMT::Base::CONFIG_FILENAME,
        YAML.dump(config)
      ).and_return(false)

      expect(Yast::Report).to receive(:Error).with('Writing configuration file failed. See YaST logs for details.')

      described_class.write_config_file(config)
    end
  end

  describe '.run_command' do
    it 'returns the exit code' do
      expect(Yast::SCR).to receive(:Execute).and_return(255)
      expect(described_class.run_command('whoami')).to be(255)
    end
  end

  describe '.ensure_default_values' do
    let(:config) do
      {
        'scc' => {
          'username' => 'user_mcuserface',
          'password' => 'password_mcpasswordface'
        }
      }
    end

    it 'handles nil' do
      expect(described_class.send(:ensure_default_values, nil)).to include('scc', 'database')
    end

    it 'sets missing defaults' do
      expect(described_class.send(:ensure_default_values, config)).to include('scc', 'database')
    end

    it 'keeps the already set parameters' do
      expect(described_class.send(:ensure_default_values, config)['scc']).to eq(config['scc'])
    end
  end
end
