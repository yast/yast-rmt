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
require 'rmt'
require 'rmt/utils'
require 'ui/event_dispatcher'

module RMT; end

class RMT::WizardSCCPage < Yast::Client
  include ::UI::EventDispatcher

  YAST_RMT_USER_AGENT = "yast2-rmt/#{RMT::VERSION}".freeze

  def initialize(config)
    textdomain 'rmt'
    @config = config
  end

  def render_content
    Wizard.SetAbortButton(:abort, Label.CancelButton)
    Wizard.SetNextButton(:next, Label.NextButton)
    Wizard.SetBackButton(:skip, Label.SkipButton)


    contents = Frame(
      _('Organization Credentials'),
      HBox(
        HSpacing(1),
        VBox(
          VSpacing(1),
          HSquash(
            MinWidth(30, InputField(Id(:scc_username), _('Organization &Username')))
          ),
          HSquash(
            MinWidth(30, Password(Id(:scc_password), _('Organization &Password')))
          ),
          VSpacing(1),
          CheckBox(Id(:scc_sync_systems), _('Forward systems to SCC')),
          VSpacing(1)
        ),
        HSpacing(1)
      )
    )

    Wizard.SetContents(
      _('RMT Configuration - Step 1/5'),
      contents,
      _('<p>Organization credentials can be found on the Organization page in the SUSE Customer Center.</p><p>https://scc.suse.com</p>'),
      true,
      true
    )

    UI.ChangeWidget(Id(:scc_username), :Value, @config['scc']['username'])
    UI.ChangeWidget(Id(:scc_password), :Value, @config['scc']['password'])
    UI.ChangeWidget(Id(:scc_sync_systems), :Value, @config['scc']['sync_systems'])
  end

  def abort_handler
    finish_dialog(:abort)
  end

  def skip_handler
    @config['scc']['username'] = UI.QueryWidget(Id(:scc_username), :Value)
    @config['scc']['password'] = UI.QueryWidget(Id(:scc_password), :Value)
    @config['scc']['sync_systems'] = UI.QueryWidget(Id(:scc_sync_systems), :Value)

    return unless Popup.AnyQuestion(
      _('Skip SCC registration?'),
      _("This is only recommended for air-gapped environments.\nRMT will not be able to sync and mirror data.\n\nDo you want to continue?"),
      _('Ignore and continue'),
      _('Go back'),
      :focus_no
    )

    RMT::Utils.write_config_file(@config)
    finish_dialog(:next)
  end

  def next_handler
    @config['scc']['username'] = UI.QueryWidget(Id(:scc_username), :Value)
    @config['scc']['password'] = UI.QueryWidget(Id(:scc_password), :Value)
    @config['scc']['sync_systems'] = UI.QueryWidget(Id(:scc_sync_systems), :Value)

    return unless scc_credentials_valid? || Popup.AnyQuestion(
      _('Continue with invalid credentials?'),
      _("Organization credentials are invalid.\nRMT will not be able to sync and mirror data.\n\nDo you want to continue?"),
      _('Ignore and continue'),
      _('Go back'),
      :focus_no
    )

    RMT::Utils.write_config_file(@config)
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
          Left(Label(_('Checking organization credentials...'))),
          VSpacing(5)
        ),
        HSpacing(5)
      )
    )

    uri = URI('https://scc.suse.com/connect/organizations/orders')
    req = Net::HTTP::Get.new(uri)
    req.basic_auth(@config['scc']['username'], @config['scc']['password'])
    req['User-Agent'] = YAST_RMT_USER_AGENT

    valid_credentials = nil
    while valid_credentials.nil?
      begin
        res = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |http| http.request(req) }
        valid_credentials = (res.code.to_i == 200)
      rescue Net::ReadTimeout
        break valid_credentials = false unless Popup.ErrorAnyQuestion(
          _('Request Timeout'),
          _("The request to SCC timed out.\n\nWould you like to try again?"),
          _('Retry'), _('Cancel'), :focus_yes
        )
      end
    end

    UI.CloseDialog

    valid_credentials
  end
end
