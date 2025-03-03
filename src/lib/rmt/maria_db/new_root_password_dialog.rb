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
module RMT::MariaDB; end

class RMT::MariaDB::NewRootPasswordDialog < RMT::Shared::SetPasswordDialog
  def initialize
    textdomain 'rmt'
    super

    @dialog_heading = _('Setting database root password')
    @dialog_label = _('The current MariaDB root password is empty. Setting a root password is required for security reasons.')
    @password_field_label = _('New MariaDB root &Password')
  end

  def set_root_password(new_root_password, hostname)
    command_file = RMT::Utils.create_protected_file(
      "SET PASSWORD FOR root@#{hostname}=PASSWORD(\"#{new_root_password}\");"
    )
    begin
      result = RMT::Utils.run_command(
        "mysql -u root < #{command_file} 2>/dev/null"
      ) == 0
    ensure
      RMT::Utils.remove_protected_file(command_file)
    end
    result
  end
end
