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
module RMT::Shared; end

class RMT::Shared::InputPasswordDialog < UI::Dialog
  def initialize
    textdomain 'rmt'
  end

  def user_input
    Yast::UI.SetFocus(Id(:password))
    super
  end

  def ok_handler
    password = Yast::UI.QueryWidget(Id(:password), :Value)

    if !password || password.empty?
      Yast::UI.SetFocus(Id(:password))
      Yast::Report.Error(_('Please provide the password.'))
      return
    elsif !password_valid?(password)
      Yast::UI.SetFocus(Id(:password))
      Yast::Report.Error(_('The provided password is not valid.'))
      return
    end

    finish_dialog(password)
  end

  private

  def dialog_content
    VBox(
      VSpacing(1),
      Heading(_(@dialog_heading)),
      VSpacing(1),
      HBox(
        HSpacing(2),
        VBox(
          Label(_(@dialog_label)),
          VSpacing(1),
          MinWidth(15, Password(Id(:password), _(@password_field_label)))
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

  def password_valid?(_password)
    raise NotImplementedError
  end
end
