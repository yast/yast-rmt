# Copyright (c) 2024 SUSE LLC.
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

require 'rmt'

describe RMT do
  describe '.VERSION' do
    subject(:version) { RMT::VERSION }

    let(:package_version) do
      filename = './package/yast2-rmt.spec'
      version = nil

      File.foreach(filename) do |line|
        line.match(/^Version:\s+(?<version>(\d+\.?){3})$/) do |match|
          version ||= match.named_captures['version']
        end
      end

      raise "'#{filename}' does not include any line matching the expected package version format." if version.nil?

      version
    end

    it 'returns the same version as specified in the package spec file' do
      expect(version).to eq package_version
    end
  end
end
