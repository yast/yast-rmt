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

  describe '#dialog_content' do
    it 'creates the UI elements' do
      expect(Yast::Term).to receive(:new).exactly(22).times
      dialog.dialog_content
    end
  end

  describe '#user_input' do
    it 'sets focus and waits for user input' do
      expect(Yast::UI).to receive(:SetFocus).with(Id(:root_password))
      expect_any_instance_of(UI::Dialog).to receive(:user_input)
      dialog.user_input
    end
  end

  describe '#ok_handler' do
    context 'when the password field is empty' do
      let(:password) { '' }

      it 'reports an error' do
        expect(Yast::UI).to receive(:QueryWidget).with(Id(:root_password), :Value).and_return(password)
        expect(Yast::UI).to receive(:SetFocus).with(Id(:root_password))
        expect(Yast::Report).to receive(:Error).with('Please provide the root password.')
        expect(dialog).not_to receive(:finish_dialog)
        dialog.ok_handler
      end
    end

    context 'when the password is invalid' do
      let(:password) { 'password' }

      it 'reports an error' do
        expect(Yast::UI).to receive(:QueryWidget).with(Id(:root_password), :Value).and_return(password)
        expect(Yast::UI).to receive(:SetFocus).with(Id(:root_password))
        expect(dialog).to receive(:root_password_valid?).and_return(false)
        expect(Yast::Report).to receive(:Error).with('The provided password is not valid.')
        expect(dialog).not_to receive(:finish_dialog)
        dialog.ok_handler
      end
    end

    context 'when the password is valid' do
      let(:password) { 'password' }

      it 'finishes the dialog and returns the password' do
        expect(Yast::UI).to receive(:QueryWidget).with(Id(:root_password), :Value).and_return(password)
        expect(dialog).to receive(:root_password_valid?).and_return(true)
        expect(dialog).to receive(:finish_dialog).with(password)
        dialog.ok_handler
      end
    end
  end

  describe '#root_password_valid?' do
    it 'returns true when exit code is 0' do
      expect(RMT::Base).to receive(:run_command).and_return(0)
      expect(dialog.root_password_valid?('password')).to be(true)
    end

    it 'returns false when exit code is not 0' do
      expect(RMT::Base).to receive(:run_command).and_return(1)
      expect(dialog.root_password_valid?('password')).to be(false)
    end
  end
end
