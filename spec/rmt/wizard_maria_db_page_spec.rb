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

  let(:config) do
    {
      'database' => {
        'username' => 'user_mcuserface',
        'password' => 'test',
        'host' => 'localhost',
        'database' => 'rmt'
      }
    }
  end

  describe '#render_content' do
    it 'renders UI elements' do
      expect(Yast::Wizard).to receive(:SetNextButton).with(:next, Yast::Label.NextButton)
      expect(Yast::Wizard).to receive(:SetContents)

      expect(Yast::UI).to receive(:ChangeWidget).with(Id(:db_username), :Value, config['database']['username'])
      expect(Yast::UI).to receive(:ChangeWidget).with(Id(:db_password), :Value, config['database']['password'])

      mariadb_page.render_content
    end
  end

  describe '#run' do
    it 'renders content and runs the event loop when the DB is not set up' do
      expect(mariadb_page).to receive(:check_db_credentials).and_return(false)
      expect(mariadb_page).to receive(:render_content)
      expect(mariadb_page).to receive(:event_loop)
      mariadb_page.run
    end

    it 'skips DB creation when DB is already set up' do
      expect(mariadb_page).to receive(:check_db_credentials).and_return(true)
      expect(Yast::Popup).to receive(:Message).with('Database has already been configured, skipping database setup.')
      expect(mariadb_page).to receive(:finish_dialog).with(:next)
      mariadb_page.run
    end
  end

  describe '#abort_handler' do
    it 'finishes when cancel button is clicked' do
      expect(mariadb_page).to receive(:finish_dialog).with(:abort)
      mariadb_page.abort_handler
    end
  end

  describe '#back_handler' do
    it 'finishes when back button is clicked' do
      expect(mariadb_page).to receive(:finish_dialog).with(:back)
      mariadb_page.back_handler
    end
  end

  describe '#next_handler' do
    let(:new_password_dialog_double) { instance_double(RMT::MariaDB::NewRootPasswordDialog) }
    let(:current_password_dialog_double) { instance_double(RMT::MariaDB::CurrentRootPasswordDialog) }
    let(:password) { 'password' }

    before do
      expect(Yast::UI).to receive(:QueryWidget).with(Id(:db_username), :Value)
      expect(Yast::UI).to receive(:QueryWidget).with(Id(:db_password), :Value)
    end

    it 'finishes if unable to start the DB' do
      expect(mariadb_page).to receive(:start_database).and_return(false)
      expect(mariadb_page).to receive(:finish_dialog).with(:next)
      mariadb_page.next_handler
    end

    context 'when current root password is empty' do
      before do
        expect(mariadb_page).to receive(:start_database).and_return(true)
        expect(mariadb_page).to receive(:root_password_empty?).and_return(true)
        expect(RMT::MariaDB::NewRootPasswordDialog).to receive(:new).and_return(new_password_dialog_double)
      end

      it 'new password must not be empty' do
        expect(new_password_dialog_double).to receive(:run).and_return('')
        expect(mariadb_page).not_to receive(:finish_dialog)
        mariadb_page.next_handler
      end

      it 'if current root password is empty, reports an error if setting new password failed' do
        expect(new_password_dialog_double).to receive(:run).and_return(password)
        expect(new_password_dialog_double).to receive(:set_root_password).and_return(false)
        expect(Yast::Report).to receive(:Error).with('Setting new database root password failed')
        expect(mariadb_page).not_to receive(:finish_dialog)
        mariadb_page.next_handler
      end

      it 'if current root password is empty, creates database and user and finished successfully' do
        expect(new_password_dialog_double).to receive(:run).and_return(password)
        expect(new_password_dialog_double).to receive(:set_root_password).and_return(true)
        expect(mariadb_page).to receive(:create_database_and_user)
        expect(RMT::Utils).to receive(:write_config_file).with(config)
        expect(mariadb_page).to receive(:finish_dialog).with(:next)
        mariadb_page.next_handler
      end
    end

    context 'when current root password is not empty' do
      before do
        expect(mariadb_page).to receive(:start_database).and_return(true)
        expect(mariadb_page).to receive(:root_password_empty?).and_return(false)
        expect(RMT::MariaDB::CurrentRootPasswordDialog).to receive(:new).and_return(current_password_dialog_double)
      end

      it 'shows error message and continues if no password was entered' do
        expect(current_password_dialog_double).to receive(:run).and_return(nil)
        expect(Yast::Report).to receive(:Error).with('Database root password not provided, skipping database setup.')
        expect(RMT::Utils).to receive(:write_config_file).with(config)
        expect(mariadb_page).to receive(:finish_dialog).with(:next)
        mariadb_page.next_handler
      end

      it 'creates database and user if current password was entered' do
        expect(current_password_dialog_double).to receive(:run).and_return(password)
        expect(mariadb_page).to receive(:create_database_and_user)
        expect(RMT::Utils).to receive(:write_config_file).with(config)
        expect(mariadb_page).to receive(:finish_dialog).with(:next)
        mariadb_page.next_handler
      end
    end
  end

  describe '#root_password_empty?' do
    it 'returns true when exit code is 0' do
      expect(RMT::Utils).to receive(:run_command).and_return(0)
      expect(mariadb_page.root_password_empty?).to be(true)
    end

    it 'returns false when exit code is not 0' do
      expect(RMT::Utils).to receive(:run_command).and_return(1)
      expect(mariadb_page.root_password_empty?).to be(false)
    end
  end

  describe '#start_database' do
    let(:service_double) do
      klass = defined?(Yast2::Systemd::Service) ? Yast2::Systemd::Service : Yast::SystemdServiceClass::Service
      instance_double(klass)
    end

    let(:service_api) do
      defined?(Yast2::Systemd::Service) ? Yast2::Systemd::Service : Yast::SystemdService
    end

    before do
      expect(Yast::UI).to receive(:OpenDialog)
      expect(service_api).to receive(:find!).with('mysql').and_return(service_double)
      expect(service_double).to receive(:running?).and_return(false)
    end

    it "raises an error when mysql can't be started" do
      expect(service_double).to receive(:start).and_return(false)
      expect(Yast::Report).to receive(:Error).with('Cannot start database service.')
      expect(mariadb_page.start_database).to be(false)
    end

    it 'returns true when mysql is started' do
      expect(service_double).to receive(:start).and_return(true)
      expect(mariadb_page.start_database).to be(true)
    end
  end

  describe '#create_database_and_user' do
    it "raises an error when can't create a database" do
      expect(RMT::Utils).to receive(:run_command).and_return(1)
      expect(Yast::Report).to receive(:Error).with('Database creation failed.')
      expect(mariadb_page.create_database_and_user).to be(false)
    end

    it "raises an error when can't create a user" do
      expect(RMT::Utils).to receive(:run_command).and_return(0, 1)
      expect(Yast::Report).to receive(:Error).with('User creation failed.')
      expect(mariadb_page.create_database_and_user).to be(false)
    end

    it 'returns true when there are no errors' do
      expect(RMT::Utils).to receive(:run_command).and_return(0, 0)
      expect(mariadb_page.create_database_and_user).to be(true)
    end
  end

  describe '#check_db_credentials' do
    context 'when the required configuration keys are missing in the DB section' do
      let(:config) { { 'database' => {} } }

      it('returns false') { expect(mariadb_page.check_db_credentials).to be(false) }
    end

    context 'when the required configuration keys are present and are invalid' do
      it 'returns false' do
        expect(RMT::Execute).to receive(:on_target!).with(
          ['echo', 'select 1;'],
          [
            'mysql', '-u', config['database']['username'], "-p#{config['database']['password']}",
            '-D', config['database']['database'], '-h', config['database']['host']
          ]
        ).and_raise(Cheetah::ExecutionFailed.new('command', 255, '', 'Something went wrong'))
        expect(mariadb_page.check_db_credentials).to be(false)
      end
    end

    context 'when the required configuration keys are present and are valid' do
      it 'returns true' do
        expect(RMT::Execute).to receive(:on_target!).with(
          ['echo', 'select 1;'],
          [
            'mysql', '-u', config['database']['username'], "-p#{config['database']['password']}",
            '-D', config['database']['database'], '-h', config['database']['host']
          ]
        )
        expect(mariadb_page.check_db_credentials).to be(true)
      end
    end
  end
end
