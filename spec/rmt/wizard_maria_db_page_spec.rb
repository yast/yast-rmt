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

require 'rmt/wizard_maria_db_page'

Yast.import 'Wizard'
Yast.import 'Report'
Yast.import 'Service'

describe RMT::WizardMariaDBPage do
  subject(:mariadb_page) { described_class.new(config) }

  let(:config) { { 'database' => { 'username' => 'user_mcuserface', 'password' => 'test' } } }

  describe '#run' do
    before do
      expect(Yast::Wizard).to receive(:SetNextButton).with(:next, Yast::Label.OKButton)
      expect(Yast::Wizard).to receive(:SetContents)

      expect(Yast::UI).to receive(:ChangeWidget).with(Id(:db_username), :Value, config['database']['username'])
      expect(Yast::UI).to receive(:ChangeWidget).with(Id(:db_password), :Value, config['database']['password'])
    end

    context 'when cancel button is clicked' do
      it 'finishes' do
        expect(Yast::UI).to receive(:UserInput).and_return(:cancel)
        expect(mariadb_page.run).to be(:cancel)
      end
    end

    context 'when back button is clicked' do
      it 'goes back' do
        expect(Yast::UI).to receive(:UserInput).and_return(:back)
        expect(mariadb_page.run).to be(:back)
      end
    end

    context 'when next button is clicked' do
      let(:new_password_dialog_double) { instance_double(RMT::MariaDB::NewRootPasswordDialog) }
      let(:current_password_dialog_double) { instance_double(RMT::MariaDB::CurrentRootPasswordDialog) }
      let(:password) { 'password' }

      it "asks for a new root password and doesn't allow empty one" do
        expect(Yast::UI).to receive(:UserInput).and_return(:next).exactly(2).times
        expect(Yast::UI).to receive(:QueryWidget).with(Id(:db_username), :Value).exactly(2).times
        expect(Yast::UI).to receive(:QueryWidget).with(Id(:db_password), :Value).exactly(2).times
        expect(mariadb_page).to receive(:start_database).and_return(true).exactly(2).times
        expect(mariadb_page).to receive(:root_password_empty?).and_return(true).exactly(2).times
        expect(RMT::MariaDB::NewRootPasswordDialog).to receive(:new).and_return(new_password_dialog_double).exactly(2).times

        # Return an empty password on the first run and expect an error to be reported
        expect(new_password_dialog_double).to receive(:run).and_return('', password)
        expect(Yast::Report).to receive(:Error).with('Setting new root password failed')

        expect(new_password_dialog_double).to receive(:set_root_password).and_return(true)

        expect(mariadb_page).to receive(:create_database_and_user).and_return(true)
        expect(RMT::Base).to receive(:write_config_file).with(config)

        expect(mariadb_page.run).to be(:next)
      end

      it 'asks for current root password and handles non-empty password' do
        expect(Yast::UI).to receive(:UserInput).and_return(:next)
        expect(Yast::UI).to receive(:QueryWidget).with(Id(:db_username), :Value)
        expect(Yast::UI).to receive(:QueryWidget).with(Id(:db_password), :Value)
        expect(mariadb_page).to receive(:start_database).and_return(true)
        expect(mariadb_page).to receive(:root_password_empty?).and_return(false)

        expect(RMT::MariaDB::CurrentRootPasswordDialog).to receive(:new).and_return(current_password_dialog_double)
        expect(current_password_dialog_double).to receive(:run).and_return(password)

        expect(mariadb_page).to receive(:create_database_and_user).and_return(true)
        expect(RMT::Base).to receive(:write_config_file).with(config)

        expect(mariadb_page.run).to be(:next)
      end

      it 'asks for current root password and handles empty password' do
        expect(Yast::UI).to receive(:UserInput).and_return(:next)
        expect(Yast::UI).to receive(:QueryWidget).with(Id(:db_username), :Value)
        expect(Yast::UI).to receive(:QueryWidget).with(Id(:db_password), :Value)
        expect(mariadb_page).to receive(:start_database).and_return(true)
        expect(mariadb_page).to receive(:root_password_empty?).and_return(false)

        expect(RMT::MariaDB::CurrentRootPasswordDialog).to receive(:new).and_return(current_password_dialog_double)
        expect(current_password_dialog_double).to receive(:run).and_return(nil)

        expect(Yast::Report).to receive(:Error).with('Root password not provided, skipping database setup.')
        expect(RMT::Base).to receive(:write_config_file).with(config)

        expect(mariadb_page.run).to be(:next)
      end
    end
  end

  describe '#root_password_empty?' do
    it 'returns true when exit code is 0' do
      expect_any_instance_of(RMT::Base).to receive(:run_command).and_return(0)
      expect(mariadb_page.root_password_empty?).to be(true)
    end

    it 'returns false when exit code is not 0' do
      expect_any_instance_of(RMT::Base).to receive(:run_command).and_return(1)
      expect(mariadb_page.root_password_empty?).to be(false)
    end
  end

  describe '#start_database' do
    # rubocop:disable RSpec/VerifiedDoubles
    # Yast::SystemdService is missing the required methods a regular class would have that are required for verifying doubles to work
    let(:service_double) { double('Yast::SystemdService') }

    # rubocop:enable RSpec/VerifiedDoubles

    before do
      expect(Yast::SystemdService).to receive(:find!).with('mysql').and_return(service_double)
      expect(service_double).to receive(:running?).and_return(false)
    end

    it "raises an error when mysql can't be started" do
      expect(service_double).to receive(:start).and_return(false)
      expect(Yast::Report).to receive(:Error).with('Cannot start mysql service.')
      expect(mariadb_page.start_database).to be(false)
    end

    it 'returns true when mysql is started' do
      expect(service_double).to receive(:start).and_return(true)
      expect(mariadb_page.start_database).to be(true)
    end
  end

  describe '#create_database_and_user' do
    it "raises an error when can't create a database" do
      expect_any_instance_of(RMT::Base).to receive(:run_command).and_return(1)
      expect(Yast::Report).to receive(:Error).with('Database creation failed.')
      expect(mariadb_page.create_database_and_user).to be(false)
    end

    it "raises an error when can't create a user" do
      expect_any_instance_of(RMT::Base).to receive(:run_command).and_return(0, 1)
      expect(Yast::Report).to receive(:Error).with('User creation failed.')
      expect(mariadb_page.create_database_and_user).to be(false)
    end

    it 'returns true when there are no errors' do
      expect_any_instance_of(RMT::Base).to receive(:run_command).and_return(0, 0)
      expect(mariadb_page.create_database_and_user).to be(true)
    end
  end
end
