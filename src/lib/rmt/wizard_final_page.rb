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
require 'rmt/ssl/certificate_generator'
require 'rmt/utils'

module RMT; end

class RMT::WizardFinalPage < Yast::Client
  include ::UI::EventDispatcher

  Yast.import 'Report'
  Yast.import 'Service'

  def initialize(config)
    textdomain 'rmt'
    @config = config
  end

  def render_content
    Wizard.SetNextButton(:next, Label.FinishButton)

    contents = HBox(
      HStretch(),
      VBox(
        Left(Heading(_('Configuration Summary'))),
        VBox(
          VSpacing(1),
          Left(Heading(_('SCC Organization:'))),
          Left(Label(@config['scc']['username'])),
          VSpacing(1),
          Left(Heading(_('RMT config file path:'))),
          Left(Label(RMT::Utils::CONFIG_FILENAME.to_s)),
          VSpacing(1),
          Left(Heading(_('SSL certificate path:'))),
          Left(Label(RMT::SSL::CertificateGenerator::RMT_SSL_DIR.to_s)),
          VSpacing(1),
          Left(Heading(_('Database credentials:'))),
          Left(HBox(HSpacing(1),
                    VBox(HBox(Label(_('Username:')), Label(@config['database']['username'])),
                         HBox(Label(_('Password:')), Label(@config['database']['password']))))),
          VSpacing(1),
          Left(Label(_('Please ensure that any firewall is configured to allow access to RMT (default ports 80 and 443)')))
        )
      ),
      HStretch()
    )

    Wizard.SetContents(
      _('RMT configuration'),
      contents,
      _('<p>This is a list of all RMT configuration performed by this wizard.</p>'\
        '<p>Please check for anything that is incorrect.</p>'),
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
    rmt_service_start
    render_content
    event_loop
  end

  def rmt_service_start
    UI.OpenDialog(
      HBox(
        HSpacing(5),
        VBox(
          VSpacing(5),
          Left(Label(_('Starting RMT service,'))),
          Left(Label(_('sync and mirror timers...'))),
          VSpacing(5)
        ),
        HSpacing(5)
      )
    )
    if Yast::Service.Enable('rmt-server') && Yast::Service.Restart('rmt-server')
      rmt_enable_timers
      Yast::Popup.Message(_("Service 'rmt-server' started, sync and mirroring systemd timers active."))
      return finish_dialog(:next)
    else
      Yast::Report.Error(_("Failed to enable and restart service 'rmt-server'"))
    end

    UI.CloseDialog
  end

  def rmt_enable_timers
    %w[rmt-server-sync.timer rmt-server-mirror.timer].each do |timer|
      RMT::Execute.on_target!('systemctl', 'enable', timer) && RMT::Execute.on_target!('systemctl', 'start', timer)
    end
  end
end
