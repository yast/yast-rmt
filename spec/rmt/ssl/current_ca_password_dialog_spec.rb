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

require 'rmt/shared/input_password_dialog'
require 'rmt/ssl/current_ca_password_dialog'

Yast.import 'Report'

describe RMT::SSL::CurrentCaPasswordDialog do
  subject(:dialog) { described_class.new }

  describe '#password_valid?' do
    let(:password) { 'foobar' }

    it 'returns true when password is valid' do
      expect_any_instance_of(RMT::SSL::CertificateGenerator).to receive(:valid_password?).with(password).and_return(true)
      expect(dialog.send(:password_valid?, password)).to be(true)
    end

    it 'returns false when exit code is not 0' do
      expect_any_instance_of(RMT::SSL::CertificateGenerator).to receive(:valid_password?).with(password).and_return(false)
      expect(dialog.send(:password_valid?, password)).to be(false)
    end
  end
end
