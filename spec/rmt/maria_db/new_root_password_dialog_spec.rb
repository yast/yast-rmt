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

  describe '#set_root_password' do
    before do
      expect(RMT::Utils).to receive(:create_protected_file).with('SET PASSWORD FOR root@localhost=PASSWORD("password");').and_return(0)
      expect(RMT::Utils).to receive(:remove_protected_file).with(anything).exactly(1).times
    end

    it 'returns true when exit code is 0' do
      expect(RMT::Utils).to receive(:run_command).and_return(0)
      expect(dialog.set_root_password('password', 'localhost')).to be(true)
    end

    it 'returns false when exit code is not 0' do
      expect(RMT::Utils).to receive(:run_command).and_return(1)
      expect(dialog.set_root_password('password', 'localhost')).to be(false)
    end
  end
end
