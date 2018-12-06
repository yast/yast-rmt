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

class RMT::WizardMariaDBPage < Yast::Client # rubocop:disable Metrics/ClassLength
  include ::UI::EventDispatcher

  def initialize(config)
    textdomain 'rmt'
    @config = config
  end

  def render_content
    contents = Frame(
      _('Database Credentials'),
      HBox(
        HSpacing(1),
        VBox(
          VSpacing(1),
          HSquash(
            MinWidth(30, InputField(Id(:db_username), _('Database &Username')))
          ),
          HSquash(
            MinWidth(30, Password(Id(:db_password), _('Database &Password')))
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
        Report.Error(_('Setting new database root password failed.'))
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

    pw_file = RMT::Utils.create_protected_file("[client]\npassword=#{@config['database']['password']}\n")
    begin
      RMT::Execute.on_target!(
        ['echo', 'select 1;'],
        [
          'mysql', "--defaults-extra-file=#{pw_file}", '-u', @config['database']['username'],
          '-D', @config['database']['database'], '-h', @config['database']['host']
        ]
      )
    ensure
      RMT::Utils.remove_protected_file(pw_file)
    end

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
    root_pw_file = RMT::Utils.create_protected_file("[client]\npassword=#{@root_password}\n")
    begin
      ret = RMT::Utils.run_command(
        "echo 'create database if not exists %1 character set = \"utf8\"' | mysql --defaults-extra-file=#{root_pw_file} -u root -h %2 2>/dev/null",
        @config['database']['database'],
        @config['database']['host']
      )
    ensure
      RMT::Utils.remove_protected_file(root_pw_file)
    end

    unless ret == 0
      Report.Error(_('Database creation failed.'))
      return false
    end

    unless @config['database']['username'] == 'root'
      root_pw_file = RMT::Utils.create_protected_file("[client]\npassword=#{@root_password}\n")
      config = Hash[@config['database'].map { |(k, v)| [k.to_sym, v] }]
      command_file = RMT::Utils.create_protected_file(
        "grant all on %<database>s.* to \"%<username>s\"\@%<host>s identified by \"%<password>s\"" % config
      )
      begin
        ret = RMT::Utils.run_command(
          "mysql --defaults-extra-file=#{root_pw_file} -u root -h %1 < #{command_file} >/dev/null",
          @config['database']['host']
        )
      ensure
        RMT::Utils.remove_protected_file(root_pw_file)
        RMT::Utils.remove_protected_file(command_file)
      end

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
