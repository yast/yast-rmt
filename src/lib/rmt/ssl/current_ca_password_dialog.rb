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
module RMT::SSL; end

class RMT::SSL::CurrentCaPasswordDialog < UI::Dialog
  def initialize
    textdomain 'rmt'

    @cert_generator = RMT::SSL::CertificateGenerator.new
  end

  def dialog_content
    VBox(
      VSpacing(1),
      Heading(_('Your CA private key is encrypted. Please input password')),
      VSpacing(1),
      HBox(
        HSpacing(2),
        VBox(
          MinWidth(15, Password(Id(:ca_password), _('&Password')))
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
    Yast::UI.SetFocus(Id(:ca_password))
    super
  end

  def ok_handler
    ca_password = Yast::UI.QueryWidget(Id(:ca_password), :Value)

    if ca_password.nil? || ca_password == ''
      Yast::UI.SetFocus(Id(:ca_password))
      Yast::Report.Error(_('Password must not be blank.'))
      return
    elsif !@cert_generator.valid_password?(ca_password)
      Yast::UI.SetFocus(Id(:ca_password))
      Yast::Report.Error(_('Password is incorrect.'))
      return
    end

    finish_dialog(ca_password)
  end
end
