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

require 'rmt/utils'
require 'ui/dialog'

module RMT; end
module RMT::Certificate; end

class RMT::Certificate::AlternativeCommonNameDialog < UI::Dialog
  def initialize
    textdomain 'rmt'
  end

  def dialog_content
    VBox(
      VSpacing(1),
      Heading(_('Add an alternative common name')),
      VSpacing(1),
      HBox(
        HSpacing(2),
        VBox(
          Label(_('Please provide the hostname or IP address.')),
          MinWidth(15, InputField(Id(:alt_name), _('Alternative name')))
        ),
        HSpacing(2)
      ),
      VSpacing(1),
      HBox(
        PushButton(Id(:cancel), Opt(:key_F9), Yast::Label.CancelButton),
        HSpacing(2),
        PushButton(Id(:ok), Opt(:default, :key_F10), Yast::Label.OKButton)
      ),
      VSpacing(1)
    )
  end

  def user_input
    Yast::UI.SetFocus(Id(:alt_name))
    super
  end

  def ok_handler
    alt_name = Yast::UI.QueryWidget(Id(:alt_name), :Value)

    if !alt_name || alt_name.empty?
      Yast::UI.SetFocus(Id(:alt_name))
      Yast::Report.Error(_('Alternative common name must not be empty.'))
      return
    end

    finish_dialog(alt_name)
  end
end
