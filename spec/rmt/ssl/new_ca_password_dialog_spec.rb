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

require 'rmt/ssl/new_ca_password_dialog'

Yast.import 'Report'

describe RMT::SSL::NewCaPasswordDialog do
  subject(:dialog) { described_class.new }

  describe '#initialize' do
    it 'creates the UI elements' do
      expect(dialog.instance_variable_get(:@dialog_heading)).to eq('Setting CA private key password')
      expect(dialog.instance_variable_get(:@dialog_label)).to eq("Please set a password for the CA private key\n" /
          "to enable RMT clients to reliably verify the\nRMT server's identity.")
      expect(dialog.instance_variable_get(:@password_field_label)).to eq('&Password')
      expect(dialog.instance_variable_get(:@password_confirmation_field_label)).to eq('C&onfirm Password')
    end
  end
end
