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

class RMT::Shared::SetPasswordDialog < UI::Dialog
  def initialize
    @min_password_size = 0
    @password_confirmation_field_label = 'C&onfirm Password'
    textdomain 'rmt'
  end

  def user_input
    Yast::UI.SetFocus(Id(:password))
    super
  end

  def ok_handler
    password = Yast::UI.QueryWidget(Id(:password), :Value)
    password_confirmation = Yast::UI.QueryWidget(Id(:password_confirmation), :Value)

    if password.nil? || password == ''
      Yast::UI.SetFocus(Id(:password))
      Yast::Report.Error(_('Password must not be blank.'))
      return
    elsif password.size < @min_password_size
      Yast::UI.SetFocus(Id(:password))
      Yast::Report.Error(_('Password has to have at least %<size>s characters.') % { size: @min_password_size })
      return
    elsif password != password_confirmation
      Yast::UI.SetFocus(Id(:password_confirmation))
      Yast::Report.Error(_('The first and the second passwords do not match.'))
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
          Label(
            _(
              @dialog_label
            )
          ),
          VSpacing(1),
          MinWidth(15, Password(Id(:password), _(@password_field_label))),
          MinWidth(15, Password(Id(:password_confirmation), _(@password_confirmation_field_label)))
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
end
