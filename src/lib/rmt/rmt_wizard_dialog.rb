require 'yaml'
require 'uri'
require 'net/http'

module Yast
  class RMTWizardDialog < Client
    include Yast::UIShortcuts
    include Yast::Logger

    CONFIG_FILENAME = '/etc/rmt.conf'

    def run
      Yast.import "UI"
      Yast.import "Wizard"
      Yast.import "Sequencer"
      Yast.import "Report"
      Yast.import "String"
      Yast.import 'SystemdService'


      textdomain "rmt"

      read_config_file

      run_wizard
    end

    def step1
      contents = Frame(
        _("SCC organization credentials"),
        HBox(
          HSpacing(1),
          VBox(
            VSpacing(1),
            HSquash(
              MinWidth(30, InputField(Id(:scc_username), _("Organization &username")))
            ),
            HSquash(
              MinWidth(30, Password(Id(:scc_password), _("Organization &password")))
            ),
            VSpacing(1)
          ),
          HSpacing(1)
        )
      )

      Wizard.SetContents(
          _("RMT configuration step 1/2"),
          contents,
          "<p>Organization credentials can be found on Organization page at <a href='https://scc.suse.com/'>SUSE Customer Center</a>.</p>",
          true,
          true
      )

      Wizard.DisableBackButton

      UI.ChangeWidget(Id(:scc_username), :Value, @config['scc']['username'])
      UI.ChangeWidget(Id(:scc_password), :Value, @config['scc']['password'])

      ret = nil
      while true
        ret = UI.UserInput
        if ret == :abort || ret == :cancel
          break
        elsif ret == :next
          @config['scc']['username'] = Convert.to_string(UI.QueryWidget(Id(:scc_username), :Value))
          @config['scc']['password'] = Convert.to_string(UI.QueryWidget(Id(:scc_password), :Value))

          break if scc_credentials_valid?

          break if Popup.AnyQuestion(
            _("Invalid SCC credentials"),
            _("SCC credentials are invalid. Please check the credentials."),
            _("Ignore and continue"),
            _("Go back"),
            :focus_no
          )
        end
      end

      deep_copy(ret)
    end

    def step2
      contents = Frame(
        _("Database credentials"),
        HBox(
          HSpacing(1),
          VBox(
            VSpacing(1),
            HSquash(
              MinWidth(30, InputField(Id(:db_username), _("Database &username")))
            ),
            HSquash(
              MinWidth(30, Password(Id(:db_password), _("Database &password")))
            ),
            VSpacing(1)
          ),
          HSpacing(1)
        )
      )

      Wizard.SetNextButton(:next, Label.OKButton)
      Wizard.SetContents(
          _("RMT configuration step 2/2"),
          contents,
          "<p>This step of the wizard performs the necessary database setup.</p>",
          true,
          true
      )

      UI.ChangeWidget(Id(:db_username), :Value, @config['database']['username'])
      UI.ChangeWidget(Id(:db_password), :Value, @config['database']['password'])

      ret = nil
      while true
        ret = UI.UserInput
        if ret == :abort || ret == :cancel
          break
        elsif ret == :next
          @config['database']['username'] = Convert.to_string(UI.QueryWidget(Id(:db_username), :Value))
          @config['database']['password'] = Convert.to_string(UI.QueryWidget(Id(:db_password), :Value))

          break unless start_database

          if root_password_empty?
            new_root_password = ask_for_new_root_password
            @root_password = set_root_password(new_root_password)
          else
            @root_password = ask_for_current_root_password
          end

          if @root_password
            create_database_and_user
          else
            Report.Error('Root password not provided, skipping database creation.')
          end

          write_config_file

          break
        elsif ret == :back
          break
        end
      end

      deep_copy(ret)
    end

    def read_config_file
      begin
        data = SCR.Read(path(".target.string"), CONFIG_FILENAME)
        @config = YAML.load(data)
      rescue StandardError => e
        log.warn "Reading config file failed: " + e.to_s
      end

      @config ||= {}
      @config['scc'] ||= {}
      @config['scc']['username'] ||= ''
      @config['scc']['password'] ||= ''

      @config['database'] ||= {}
      @config['database']['database'] ||= 'rmt'
      @config['database']['username'] ||= 'rmt'
      @config['database']['password'] ||= ''
      @config['database']['hostname'] ||= 'localhost'
    end

    def write_config_file
      SCR.Write(path(".target.string"), CONFIG_FILENAME, YAML.dump(@config))
      Popup.Message("Configuration written successfully!")
    end

    def scc_credentials_valid?
      UI.OpenDialog(
        HBox(
          HSpacing(5),
          VBox(
            VSpacing(5),
            Left(Label(_("Checking SCC credentials..."))),
            VSpacing(5)
          ),
          HSpacing(5)
        )
      )

      uri = URI('https://scc.suse.com/connect/organizations/systems')
      req = Net::HTTP::Get.new(uri)
      req.basic_auth(@config['scc']['username'], @config['scc']['password'])

      res = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |http| http.request(req) }

      UI.CloseDialog

      res.code.to_i == 200
    end

    def run_wizard
      aliases = {
          "step1" => lambda { step1() },
          "step2" => lambda { step2() }
      }

      sequence = {
          "ws_start" => "step1",
          "step1"   => { :abort => :abort, :next => "step2" },
          "step2"   => { :abort => :abort, :next => :next }
      }

      Wizard.CreateDialog()
      Wizard.SetTitleIcon("yast-rmt")
      Wizard.SetAbortButton(:abort, Label.CancelButton)
      Wizard.SetNextButton(:next, Label.NextButton)

      ret = Sequencer.Run(aliases, sequence)

      Wizard.RestoreNextButton
      Wizard.RestoreAbortButton
      Wizard.RestoreBackButton

      UI.CloseDialog()
    end

    # Runs a command and returns the exit code
    def run_command(command, *params)
      params = params.map { |p| String.Quote(p) }

      Convert.to_integer(
        SCR.Execute(
          path(".target.bash"),
          Builtins.sformat(command, *params)
        )
      )
    end

    def root_password_empty?
      run_command(
        "echo 'show databases;' | mysql -u root -h %1 2>/dev/null",
        @config['database']['hostname']
      ) == 0
    end

    def root_password_valid?(password)
      run_command(
        "echo 'show databases;' | mysql -u root -h %1 -p%2 2>/dev/null",
        @config['database']['hostname'],
        password
      ) == 0
    end

    def ask_for_current_root_password
      ret = nil

      UI.OpenDialog(
        VBox(
          VSpacing(1),
          Heading(_("Database root password is required")),
          VSpacing(1),
          HBox(
            HSpacing(2),
            VBox(
              Label(_("Please provide the current database root password.")),
              MinWidth(15, Password(Id(:root_password), _("MariaDB root &password"))),
            ),
            HSpacing(2)
          ),
          VSpacing(1),
          HBox(
            PushButton(Id(:cancel), Opt(:key_F9), Label.CancelButton),
            HSpacing(2),
            PushButton(Id(:ok), Opt(:default, :key_F10), Label.OKButton)
          ),
          VSpacing(1)
        )
      )

      UI.SetFocus(Id(:root_password))

      while true
        user_ret = UI.UserInput

        if user_ret == :cancel
          ret = nil
          break
        elsif user_ret == :ok
          root_password = Convert.to_string(UI.QueryWidget(Id(:root_password), :Value))

          if !root_password or root_password.empty?
            UI.SetFocus(Id(:root_password))
            Report.Error(_('Please provide the root password.'))
            next
          elsif !root_password_valid?(root_password)
            UI.SetFocus(Id(:root_password))
            Report.Error(_('The provided password is not valid.'))
            next
          end

          ret = root_password
          break
        end
      end

      UI.CloseDialog

      ret
    end

    def ask_for_new_root_password
      ret = nil

      UI.OpenDialog(
        VBox(
          VSpacing(1),
          Heading(_("Setting database root password")),
          VSpacing(1),
          HBox(
            HSpacing(2),
            VBox(
              Label(
                _(
                  "The current MariaDB root password is empty.\n" +
                  "Setting a root password is required for security reasons."
                )
              ),
              VSpacing(1),
              MinWidth(15, Password(Id(:new_root_password_1), _("New MariaDB root &Password"))),
              MinWidth(15, Password(Id(:new_root_password_2), _("New Password &Again"))),
            ),
            HSpacing(2)
          ),
          VSpacing(1),
          HBox(
            PushButton(Id(:cancel), Opt(:key_F9), Label.CancelButton),
            HSpacing(2),
            PushButton(Id(:ok), Opt(:default, :key_F10), Label.OKButton)
          ),
          VSpacing(1)
        )
      )

      UI.SetFocus(Id(:new_root_password_1))

      while true
        user_ret = UI.UserInput

        if user_ret == :cancel
          ret = nil
          break
        elsif user_ret == :ok
          pass_1 = Convert.to_string(UI.QueryWidget(Id(:new_root_password_1), :Value))
          pass_2 = Convert.to_string(UI.QueryWidget(Id(:new_root_password_2), :Value))

          if pass_1 == nil || pass_1 == ""
            UI.SetFocus(Id(:new_root_password_1))
            Report.Error(_("Password must not be blank."))
            next
          elsif pass_1 != pass_2
            UI.SetFocus(Id(:new_root_password_2))
            Report.Error(_("The first and the second password do not match."))
            next
          end

          ret = pass_1
          break
        end
      end

      UI.CloseDialog

      ret
    end

    def start_database
      service = Yast::SystemdService.find!('mysql')
      is_running = service.running? ? true : service.start

      unless is_running
        Report.Error(_("Cannot start mysql service."))
        return false
      end

      true
    end

    def set_root_password(new_root_password)
      run_command(
        "echo 'SET PASSWORD FOR root@%1=PASSWORD(\"%2\");' | mysql -u root -h %3 2>/dev/null",
        @config['database']['hostname'],
        new_root_password,
        @config['database']['hostname']
      ) == 0
    end

    def create_database_and_user
      ret = run_command(
        "echo 'create database if not exists %1 character set = \"utf8\"' | mysql -u root -h %2 -p%3 2>/dev/null",
        @config['database']['database'],
        @config['database']['hostname'],
        @root_password
      )

      unless ret == 0
        Report.Error(_("Database creation failed."))
        return false
      end

      unless @config['database']['username'] == 'root'
        ret = run_command(
          "echo 'grant all on %1.* to \"%2\"\@%3 identified by \"%4\"' | mysql -u root -h %5 -p%6 >/dev/null",
          @config['database']['database'],
          @config['database']['username'],
          @config['database']['hostname'],
          @config['database']['password'],
          @config['database']['hostname'],
          @root_password
        )

        unless ret == 0
          Report.Error(_("User creation failed."))
          return false
        end
      end

      true
    end

  end
end