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
require 'rmt/shared/set_password_dialog'
require 'ui/dialog'

module RMT; end
module RMT::SSL; end

class RMT::SSL::NewCaPasswordDialog < RMT::Shared::SetPasswordDialog
  def initialize
    super

    @dialog_heading = 'Setting CA private key password'
    @dialog_label = 'Please set new CA private key password'
    @password_field_label = 'New CA private key &Password'
    @password_confirmation_field_label = 'New Password &Again'
  end
end
