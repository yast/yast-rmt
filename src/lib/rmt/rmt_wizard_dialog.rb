require 'yaml'
require 'uri'
require 'net/http'

module Yast
  class RMTWizardDialog < Client
    include Yast::UIShortcuts

    CONFIG_FILENAME = '/etc/rmt.conf'

    def run
      Yast.import "UI"
      Yast.import "Wizard"
      Yast.import "Sequencer"

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
          "<p>Organization credentials can be found on Organization page at <a href='https://scc.suse.com'>https://scc.suse.com</a></p>",
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

          break if check_scc_credentials # FIXME display a message that check is in progress

          Popup.Message("SCC credentials are invalid!") # FIXME need some way to continue even if ivalid

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
          "There's no help! You are on your own!",
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

          write_config_file

          break
        elsif ret == :back
          break
        end
      end

      deep_copy(ret)
    end

    def read_config_file
      data = SCR.Read(path(".target.string"), CONFIG_FILENAME)
      begin
        @config = YAML.load(data)
      rescue StandardError => e
        puts e # FIXME log to Yast log
      end

      @config ||= {}
      @config['scc'] ||= {}
      @config['scc']['username'] ||= ""
      @config['scc']['password'] ||= ""

      @config['database'] ||= {}
      @config['database']['username'] ||= ""
      @config['database']['password'] ||= ""
    end

    def write_config_file
      SCR.Write(path(".target.string"), CONFIG_FILENAME, YAML.dump(@config))
      Popup.Message("Configuration written successfully!")
    end

    def check_scc_credentials
      uri = URI('https://scc.suse.com/connect/organizations/systems')
      req = Net::HTTP::Get.new(uri)
      req.basic_auth(@config['scc']['username'], @config['scc']['password'])

      res = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |http| http.request(req) }

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
  end
end