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
require 'rmt/utils'
require 'ui/event_dispatcher'

module RMT; end

class RMT::WizardSCCPage < Yast::Client
  include ::UI::EventDispatcher

  def initialize(config)
    textdomain 'rmt'
    @config = config
  end

  def render_content
    Wizard.SetAbortButton(:abort, Label.CancelButton)
    Wizard.SetNextButton(:next, Label.NextButton)

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
  end

  def abort_handler
    finish_dialog(:abort)
  end

  def next_handler
    @config['scc']['username'] = UI.QueryWidget(Id(:scc_username), :Value)
    @config['scc']['password'] = UI.QueryWidget(Id(:scc_password), :Value)

    return unless scc_credentials_valid? || Popup.AnyQuestion(
      _('Invalid SCC credentials'),
      _('SCC credentials are invalid. Please check the credentials.'),
      _('Ignore and continue'),
      _('Go back'),
      :focus_no
    )

    finish_dialog(:next)
  end

  def run
    render_content
    event_loop
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
end
