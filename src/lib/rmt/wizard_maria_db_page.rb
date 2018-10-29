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
require 'rmt/maria_db/new_root_password_dialog'
require 'rmt/execute'
require 'ui/event_dispatcher'

# In yast2 4.1.3 a reorganization of the YaST systemd library was introduced. When running on an
# older version, just fall back to the old SystemdService module (bsc#1107253).
begin
  require 'yast2/systemd/service'
rescue LoadError
  Yast.import 'SystemdService'
end

module RMT; end

class RMT::WizardMariaDBPage < Yast::Client
  include ::UI::EventDispatcher

  def initialize(config)
    textdomain 'rmt'
    @config = config
  end

  def render_content
    contents = Frame(
      _('Database credentials'),
      HBox(
        HSpacing(1),
        VBox(
          VSpacing(1),
          HSquash(
            MinWidth(30, InputField(Id(:db_username), _('Database &username')))
          ),
          HSquash(
            MinWidth(30, Password(Id(:db_password), _('Database &password')))
          ),
          VSpacing(1)
        ),
        HSpacing(1)
      )
    )

    Wizard.SetNextButton(:next, Label.NextButton)
    Wizard.SetContents(
      _('RMT Configuration - Step 2/5'),
      contents,
      _('<p>This step of the wizard performs the necessary database setup.</p>'),
      true,
      true
    )

    UI.ChangeWidget(Id(:db_username), :Value, @config['database']['username'])
    UI.ChangeWidget(Id(:db_password), :Value, @config['database']['password'])
  end

  def abort_handler
    finish_dialog(:abort)
  end

  def back_handler
    finish_dialog(:back)
  end

  def next_handler
    @config['database']['username'] = UI.QueryWidget(Id(:db_username), :Value)
    @config['database']['password'] = UI.QueryWidget(Id(:db_password), :Value)

    return finish_dialog(:next) unless start_database

    if root_password_empty?
      dialog = RMT::MariaDB::NewRootPasswordDialog.new
      new_root_password = dialog.run

      if !new_root_password || new_root_password.empty? || !dialog.set_root_password(new_root_password, @config['database']['host'])
        Report.Error(_('Setting new database root password failed'))
        return
      end

      @root_password = new_root_password
    else
      dialog = RMT::MariaDB::CurrentRootPasswordDialog.new
      @root_password = dialog.run
    end

    if @root_password
      create_database_and_user
    else
      Report.Error(_('Database root password not provided, skipping database setup.'))
    end

    RMT::Utils.write_config_file(@config)
    finish_dialog(:next)
  end

  def run
    if check_db_credentials
      Yast::Popup.Message(_('Database has already been configured, skipping database setup.'))
      return finish_dialog(:next)
    end
    render_content
    event_loop
  end

  def check_db_credentials
    %w[username password database host].each do |key|
      return false if (!@config['database'][key] || @config['database'][key].empty?)
    end

    RMT::Execute.on_target!(
      ['echo', 'select 1;'],
      [
        'mysql', '-u', @config['database']['username'], "-p#{@config['database']['password']}",
        '-D', @config['database']['database'], '-h', @config['database']['host']
      ]
    )
    true
  rescue Cheetah::ExecutionFailed
    false
  end

  def root_password_empty?
    RMT::Utils.run_command(
      "echo 'show databases;' | mysql -u root -h %1 2>/dev/null",
      @config['database']['host']
    ) == 0
  end

  def start_database
    UI.OpenDialog(
      HBox(
        HSpacing(5),
        VBox(
          VSpacing(5),
          Left(Label(_('Starting database service...'))),
          VSpacing(5)
        ),
        HSpacing(5)
      )
    )
    service = find_service('mysql')
    is_running = service.running? ? true : service.start

    unless is_running
      Report.Error(_('Cannot start database service.'))
      return false
    end

    UI.CloseDialog

    true
  end

  def create_database_and_user
    ret = RMT::Utils.run_command(
      "echo 'create database if not exists %1 character set = \"utf8\"' | mysql -u root -h %2 -p%3 2>/dev/null",
      @config['database']['database'],
      @config['database']['host'],
      @root_password
    )

    unless ret == 0
      Report.Error(_('Database creation failed.'))
      return false
    end

    unless @config['database']['username'] == 'root'
      ret = RMT::Utils.run_command(
        "echo 'grant all on %1.* to \"%2\"\@%3 identified by \"%4\"' | mysql -u root -h %5 -p%6 >/dev/null",
        @config['database']['database'],
        @config['database']['username'],
        @config['database']['host'],
        @config['database']['password'],
        @config['database']['host'],
        @root_password
      )

      unless ret == 0
        Report.Error(_('User creation failed.'))
        return false
      end
    end

    true
  end

  private

  # Returns the Systemd service
  #
  # @note This method falls back to Yast::SystemdService if the new API (Yast2::Systemd::Service)
  #   is not defined.
  # @param name [String] Service's name
  # @return [Yast2::Systemd::Service,Yast::SystemdServiceClass::Service]
  def find_service(name)
    service_api = defined?(Yast2::Systemd::Service) ? Yast2::Systemd::Service : Yast::SystemdService
    service_api.find!(name)
  end
end
