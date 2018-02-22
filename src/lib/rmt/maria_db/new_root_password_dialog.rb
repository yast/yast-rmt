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

require 'rmt/base'

module RMT; end
module RMT::MariaDB; end

class RMT::MariaDB::NewRootPasswordDialog < RMT::Base
  def run
    ret = nil

    UI.OpenDialog(
      VBox(
        VSpacing(1),
        Heading(_('Setting database root password')),
        VSpacing(1),
        HBox(
          HSpacing(2),
          VBox(
            Label(
              _(
                "The current MariaDB root password is empty.\n" \
                    'Setting a root password is required for security reasons.'
              )
            ),
            VSpacing(1),
            MinWidth(15, Password(Id(:new_root_password_1), _('New MariaDB root &Password'))),
            MinWidth(15, Password(Id(:new_root_password_2), _('New Password &Again')))
          ),
          HSpacing(2)
        ),
        VSpacing(1),
        HBox(
          PushButton(Id(:cancel), Opt(:key_F9), Label.CancelButton),
          HSpacing(2),
          PushButton(Id(:ok), Opt(:default, :key_F10), Label.OKButton)
        ),
        VSpacing(1)
      )
    )

    UI.SetFocus(Id(:new_root_password_1))

    loop do
      user_ret = UI.UserInput

      if user_ret == :cancel
        ret = nil
        break
      elsif user_ret == :ok
        pass1 = UI.QueryWidget(Id(:new_root_password_1), :Value)
        pass2 = UI.QueryWidget(Id(:new_root_password_2), :Value)

        if pass1.nil? || pass1 == ''
          UI.SetFocus(Id(:new_root_password_1))
          Report.Error(_('Password must not be blank.'))
          next
        elsif pass1 != pass2
          UI.SetFocus(Id(:new_root_password_2))
          Report.Error(_('The first and the second passwords do not match.'))
          next
        end

        ret = pass1
        break
      end
    end

    UI.CloseDialog

    ret
  end

  def set_root_password(new_root_password, hostname)
    run_command(
      "echo 'SET PASSWORD FOR root@%1=PASSWORD(\"%2\");' | mysql -u root 2>/dev/null",
      hostname,
      new_root_password
    ) == 0
  end
end
