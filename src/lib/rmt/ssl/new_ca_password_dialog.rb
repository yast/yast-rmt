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
    textdomain 'rmt'
    super

    @dialog_heading = _('Setting CA private key password')
    @dialog_label = _('Please set a password for the CA private key.')
    @password_field_label = _('&Password')
    @min_password_size = 4
  end
end
