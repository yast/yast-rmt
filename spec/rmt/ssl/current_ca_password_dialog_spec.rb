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

require 'rmt/ssl/current_ca_password_dialog'

Yast.import 'Report'

describe RMT::SSL::CurrentCaPasswordDialog do
  subject(:dialog) { described_class.new }

  describe '#dialog_content' do
    it 'creates the UI elements' do
      expect(Yast::Term).to receive(:new).exactly(21).times
      dialog.dialog_content
    end
  end

  describe '#user_input' do
    it 'sets focus and waits for user input' do
      expect(Yast::UI).to receive(:SetFocus).with(Id(:ca_password))
      expect_any_instance_of(UI::Dialog).to receive(:user_input)
      dialog.user_input
    end
  end

  describe '#ok_handler' do
    let(:ca_password) { 'foobar' }

    context 'with valid password' do
      it 'continues' do
        expect(Yast::UI).to receive(:QueryWidget).with(Id(:ca_password), :Value).and_return(ca_password)
        allow_any_instance_of(RMT::SSL::CertificateGenerator).to receive(:valid_password?).with(ca_password).and_return(true)
        expect(dialog).to receive(:finish_dialog)
        dialog.ok_handler
      end
    end

    context 'with invalid password' do
      it 'reports an error' do
        expect(Yast::UI).to receive(:QueryWidget).with(Id(:ca_password), :Value).and_return(ca_password)
        expect(Yast::UI).to receive(:SetFocus).with(Id(:ca_password))
        allow_any_instance_of(RMT::SSL::CertificateGenerator).to receive(:valid_password?).with(ca_password).and_return(false)
        expect(Yast::Report).to receive(:Error).with('Password is incorrect.')
        expect(dialog).not_to receive(:finish_dialog)
        dialog.ok_handler
      end
    end

    context 'with blank password' do
      it 'reports an error' do
        expect(Yast::UI).to receive(:QueryWidget).with(Id(:ca_password), :Value).and_return('')
        expect(Yast::UI).to receive(:SetFocus).with(Id(:ca_password))
        allow_any_instance_of(RMT::SSL::CertificateGenerator).to receive(:valid_password?).with(ca_password).and_return(false)
        expect(Yast::Report).to receive(:Error).with('Password must not be blank.')
        expect(dialog).not_to receive(:finish_dialog)
        dialog.ok_handler
      end
    end
  end
end
