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

require 'rmt/maria_db/current_root_password_dialog'

Yast.import 'Report'

describe RMT::MariaDB::CurrentRootPasswordDialog do
  subject(:dialog) { described_class.new }

  describe '#run' do
    before do
      expect(Yast::UI).to receive(:OpenDialog)
      expect(Yast::UI).to receive(:CloseDialog)
    end

    context 'when cancel is pressed' do
      it 'returns nil' do
        expect(Yast::UI).to receive(:SetFocus).with(Id(:root_password))
        expect(Yast::UI).to receive(:UserInput).and_return(:cancel)
        expect(dialog.run).to be(nil)
      end
    end

    context 'when OK is pressed and empty password is supplied' do
      let(:bad_password) { '' }
      let(:good_password) { 'good_password' }

      it 'asks for non-empty password' do
        expect(Yast::UI).to receive(:QueryWidget).with(Id(:root_password), :Value).and_return(bad_password, good_password)
        expect(Yast::UI).to receive(:UserInput).exactly(2).times.and_return(:ok)
        expect(Yast::UI).to receive(:SetFocus).with(Id(:root_password)).exactly(2).times
        expect(Yast::Report).to receive(:Error).with('Please provide the root password.')
        expect(dialog).to receive(:root_password_valid?).and_return(true)
        expect(dialog.run).to be(good_password)
      end
    end

    context 'when OK is pressed and invalid password is supplied' do
      let(:bad_password) { 'bad_password' }
      let(:good_password) { 'good_password' }

      it 'asks for a valid empty password' do
        expect(Yast::UI).to receive(:QueryWidget).with(Id(:root_password), :Value).and_return(bad_password, good_password)
        expect(Yast::UI).to receive(:UserInput).exactly(2).times.and_return(:ok)
        expect(Yast::UI).to receive(:SetFocus).with(Id(:root_password)).exactly(2).times
        expect(Yast::Report).to receive(:Error).with('The provided password is not valid.')
        expect(dialog).to receive(:root_password_valid?).and_return(false, true)
        expect(dialog.run).to be(good_password)
      end
    end
  end

  describe '#root_password_valid?' do
    it 'returns true when exit code is 0' do
      expect_any_instance_of(RMT::Base).to receive(:run_command).and_return(0)
      expect(dialog.root_password_valid?('password')).to be(true)
    end

    it 'returns false when exit code is not 0' do
      expect_any_instance_of(RMT::Base).to receive(:run_command).and_return(1)
      expect(dialog.root_password_valid?('password')).to be(false)
    end
  end
end
