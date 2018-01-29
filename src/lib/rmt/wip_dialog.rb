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

#  To contact Novell about this file by physical or electronic mail,
#  you may find current contact information at www.suse.com

require "yast"

Yast.import "UI"
Yast.import "Label"

module Rmt
  class WipDialog
    include Yast::UIShortcuts
    include Yast::I18n
    include Yast::Logger

    def run
      return unless create_dialog

      begin
        return event_loop
      ensure
        close_dialog
      end
    end

    def event_loop
      loop do
        input = Yast::UI.UserInput
        if input == :cancel
          # Break the loop
          break
        else
          log.warn "Unexpected input #{input}"
        end
      end
    end

    def create_dialog
      Yast::UI.OpenDialog(
        Opt(:decorated, :defaultsize),
        VBox(
          # Header
          Heading(_("yast2-rmt module is still in development.")),

          # Quit button
          PushButton(Id(:cancel), Yast::Label.QuitButton)
        )
      )
    end

    def close_dialog
      Yast::UI.CloseDialog
    end
  end
end
