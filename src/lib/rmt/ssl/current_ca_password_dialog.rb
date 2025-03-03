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
require 'rmt/ssl/certificate_generator'
require 'rmt/shared/input_password_dialog'
require 'ui/dialog'

module RMT; end
module RMT::SSL; end

class RMT::SSL::CurrentCaPasswordDialog < RMT::Shared::InputPasswordDialog
  def initialize
    textdomain 'rmt'
    super

    @dialog_heading = _('Your CA private key is encrypted.')
    @dialog_label = _('Please input password.')
    @password_field_label = _('&Password')
    @cert_generator = RMT::SSL::CertificateGenerator.new
  end

  private

  def password_valid?(password)
    @cert_generator.valid_password?(password)
  end
end
