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

  describe '#dialog_content' do
    it 'creates the UI elements' do
      expect(Yast::Term).to receive(:new).exactly(26).times
      dialog.dialog_content
    end
  end

  describe '#user_input' do
    it 'sets focus and waits for user input' do
      expect(Yast::UI).to receive(:SetFocus).with(Id(:new_root_password_1))
      expect_any_instance_of(UI::Dialog).to receive(:user_input)
      dialog.user_input
    end
  end

  describe '#ok_handler' do
    before do
      expect(Yast::UI).to receive(:QueryWidget).with(Id(:new_root_password_1), :Value).and_return(password1)
      expect(Yast::UI).to receive(:QueryWidget).with(Id(:new_root_password_2), :Value).and_return(password2)
    end

    context 'when the password is blank' do
      let(:password1) { '' }
      let(:password2) { 'good_password' }

      it 'reports an error' do
        expect(Yast::UI).to receive(:SetFocus).with(Id(:new_root_password_1))
        expect(Yast::Report).to receive(:Error).with('Password must not be blank.')

        expect(dialog).not_to receive(:finish_dialog)
        dialog.ok_handler
      end
    end

    context 'when the password is blank' do
      let(:password1) { 'bad_password' }
      let(:password2) { 'good_password' }

      it 'reports an error' do
        expect(Yast::UI).to receive(:SetFocus).with(Id(:new_root_password_2))
        expect(Yast::Report).to receive(:Error).with('The first and the second passwords do not match.')

        expect(dialog).not_to receive(:finish_dialog)
        dialog.ok_handler
      end
    end

    context 'when the passwords match' do
      let(:password1) { 'good_password' }
      let(:password2) { 'good_password' }

      it 'finishes the dialog and returns the password' do
        expect(dialog).to receive(:finish_dialog).with(password1)
        dialog.ok_handler
      end
    end
  end

  describe '#set_root_password' do
    it 'returns true when exit code is 0' do
      expect(RMT::Base).to receive(:run_command).and_return(0)
      expect(dialog.set_root_password('localhost', 'password')).to be(true)
    end

    it 'returns false when exit code is not 0' do
      expect(RMT::Base).to receive(:run_command).and_return(1)
      expect(dialog.set_root_password('localhost', 'password')).to be(false)
    end
  end
end
