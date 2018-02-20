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

require 'uri'
require 'net/http'
require 'rmt/base'
require 'rmt/wizard_mariadb_page'

module RMT
end

class RMT::Wizard < RMT::Base
  include Yast::UIShortcuts
  include Yast::Logger

  def run
    Yast.import 'UI'
    Yast.import 'Wizard'
    Yast.import 'Sequencer'
    Yast.import 'Report'
    Yast.import 'String'
    Yast.import 'SystemdService'

    textdomain 'rmt'

    @config = RMT::Base.read_config_file

    run_wizard
  end

  def step1
    contents = Frame(
      _('SCC organization credentials'),
      HBox(
        HSpacing(1),
        VBox(
          VSpacing(1),
          HSquash(
            MinWidth(30, InputField(Id(:scc_username), _('Organization &username')))
          ),
          HSquash(
            MinWidth(30, Password(Id(:scc_password), _('Organization &password')))
          ),
          VSpacing(1)
        ),
        HSpacing(1)
      )
    )

    Wizard.SetContents(
      _('RMT configuration step 1/2'),
        contents,
        "<p>Organization credentials can be found on Organization page at <a href='https://scc.suse.com/'>SUSE Customer Center</a>.</p>",
        true,
        true
    )

    Wizard.DisableBackButton

    UI.ChangeWidget(Id(:scc_username), :Value, @config['scc']['username'])
    UI.ChangeWidget(Id(:scc_password), :Value, @config['scc']['password'])

    ret = nil
    loop do
      ret = UI.UserInput
      if ret == :abort || ret == :cancel
        break
      elsif ret == :next
        @config['scc']['username'] = Convert.to_string(UI.QueryWidget(Id(:scc_username), :Value))
        @config['scc']['password'] = Convert.to_string(UI.QueryWidget(Id(:scc_password), :Value))

        break if scc_credentials_valid?

        break if Popup.AnyQuestion(
          _('Invalid SCC credentials'),
          _('SCC credentials are invalid. Please check the credentials.'),
          _('Ignore and continue'),
          _('Go back'),
          :focus_no
        )
      end
    end

    deep_copy(ret)
  end

  def step2
    RMT::WizardMariaDBPage.new(@config)
  end

  def scc_credentials_valid?
    UI.OpenDialog(
      HBox(
        HSpacing(5),
        VBox(
          VSpacing(5),
          Left(Label(_('Checking SCC credentials...'))),
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
      'step1' => -> { step1 },
      'step2' => -> { step2 }
    }

    sequence = {
      'ws_start' => 'step1',
      'step1'   => { abort: :abort, next: 'step2' },
      'step2'   => { abort: :abort, next: :next }
    }

    Wizard.CreateDialog()
    Wizard.SetTitleIcon('yast-rmt')
    Wizard.SetAbortButton(:abort, Label.CancelButton)
    Wizard.SetNextButton(:next, Label.NextButton)

    Sequencer.Run(aliases, sequence)

    Wizard.RestoreNextButton
    Wizard.RestoreAbortButton
    Wizard.RestoreBackButton

    UI.CloseDialog()
  end
end
