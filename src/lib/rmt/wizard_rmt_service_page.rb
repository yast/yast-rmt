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

require 'ui/event_dispatcher'
require 'rmt/utils'

module RMT; end

class RMT::WizardRMTServicePage < Yast::Client
  include ::UI::EventDispatcher

  Yast.import 'Service'

  def initialize(config)
    textdomain 'rmt'
    @config = config
  end

  def render_content
    Wizard.SetNextButton(:next, Label.NextButton)

    contents = Frame(
      _('RMT Service Status'),
      HBox(
        HSpacing(1),
        VBox(
          HSquash(
            Label(Id(:service_status), _("Service 'rmt-server' started, sync and mirroring systemd timers active."))
          )
        )
      )
    )

    Wizard.SetContents(
      _('RMT configuration step 5/5'),
      contents,
      _('<p>Starting the necessary services for RMT.</p>'),
      true,
      true
    )
  end

  def next_handler
    finish_dialog(:next)
  end

  def abort_handler
    finish_dialog(:abort)
  end

  def back_handler
    finish_dialog(:back)
  end

  def run
    render_content
    rmt_services_started = false
    nginx_service_reloaded = false

    Yast::Popup.Feedback(_('Starting RMT'), _('Starting RMT server, sync and mirror timers ...')) do
      rmt_services_started = rmt_service_start
    end
    unless rmt_services_started
      UI.ChangeWidget(Id(:service_status), :Value, _('Could not start RMT services and timers.'))
      Yast::Report.Error(_('Failed to enable and restart RMT services and timers'))
    end

    Yast::Popup.Feedback(_('Reloading nginx'), _('Reloading the nginx service ...')) do
      nginx_service_reloaded = nginx_service_reload
    end
    unless nginx_service_reloaded
      UI.ChangeWidget(Id(:service_status), :Value, _('Could not reload \'nginx\' service.'))
      Yast::Report.Error(_('Failed to reload service for \'nginx\''))
    end

    event_loop
  end

  def nginx_service_reload
    return true if Yast::Service.Reload('nginx')
    false
  end

  def rmt_service_start
    if Yast::Service.Enable('rmt-server') && Yast::Service.Restart('rmt-server')
      rmt_enable_timers
      return true
    end
    false
  end

  def rmt_enable_timers
    %w[rmt-server-sync.timer rmt-server-mirror.timer].each do |timer|
      RMT::Execute.on_target!('systemctl', 'enable', timer)
      RMT::Execute.on_target!('systemctl', 'start', timer)
    end
  end
end
