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

    contents =
      VBox(
        Heading(_('Configuration Summary')),
        HBox(
          HSpacing(1),
          VBox(
            VSpacing(1),
              Frame(
                _('Location of config files'),
                HBox(
                  Label(_('Locations go here'))
                )
              ),
              VSpacing(1),
              Frame(
                _('Location of SSL files'),
                HBox(
                  Label(_('Locations go here'))
                )
              ),
            VSpacing(1)
          )
        )
      )

    Wizard.SetContents(
      _('RMT configuration'),
      contents,
      _('<p>This is a list of all RMT configuration so far.</p>'\
        '<p>Please check for anything that is incorrect or go back one step.</p>'),
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
    Yast::Report.Error(_("Failed to enable and restart service 'rmt'")) unless (Yast::Service.Enable('rmt') && Yast::Service.Restart('rmt'))
    render_content
    event_loop
  end
end
