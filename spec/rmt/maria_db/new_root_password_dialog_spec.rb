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

require 'rmt/maria_db/new_root_password_dialog'

Yast.import 'Report'

describe RMT::MariaDB::NewRootPasswordDialog do
  subject(:dialog) { described_class.new }

  describe '#run' do
    before do
      expect(Yast::UI).to receive(:OpenDialog)
      expect(Yast::UI).to receive(:CloseDialog)
      expect(Yast::UI).to receive(:SetFocus).with(Id(:new_root_password_1))
    end

    context 'when cancel is pressed' do
      it 'returns nil' do
        expect(Yast::UI).to receive(:UserInput).and_return(:cancel)
        expect(dialog.run).to be(nil)
      end
    end

    context 'when OK is pressed' do
      before do
        expect(Yast::UI).to receive(:UserInput).exactly(2).times.and_return(:ok)
        expect(Yast::UI).to receive(:QueryWidget).with(Id(:new_root_password_1), :Value).and_return(bad_password, good_password)
        expect(Yast::UI).to receive(:QueryWidget).with(Id(:new_root_password_2), :Value).and_return(good_password, good_password)
      end

      context 'when password is empty' do
        let(:bad_password) { '' }
        let(:good_password) { 'good_password' }

        it 'complains about empty password and returns good password' do
          expect(Yast::UI).to receive(:SetFocus).with(Id(:new_root_password_1))
          expect(Yast::Report).to receive(:Error).with('Password must not be blank.')

          expect(dialog.run).to be(good_password)
        end
      end

      context 'when password is not empty' do
        let(:bad_password) { 'bad_password' }
        let(:good_password) { 'good_password' }

        it 'complains about non-matching passwords and returns good password' do
          expect(Yast::UI).to receive(:SetFocus).with(Id(:new_root_password_2))
          expect(Yast::Report).to receive(:Error).with('The first and the second passwords do not match.')

          expect(dialog.run).to be(good_password)
        end
      end
    end
  end

  describe '#set_root_password' do
    it 'returns true when exit code is 0' do
      expect_any_instance_of(RMT::Base).to receive(:run_command).and_return(0)
      expect(dialog.set_root_password('localhost', 'password')).to be(true)
    end

    it 'returns false when exit code is not 0' do
      expect_any_instance_of(RMT::Base).to receive(:run_command).and_return(1)
      expect(dialog.set_root_password('localhost', 'password')).to be(false)
    end
  end
end
