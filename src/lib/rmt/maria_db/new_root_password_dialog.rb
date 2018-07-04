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
    super

    @dialog_heading = 'Setting database root password'
    @dialog_label = "The current MariaDB root password is empty.\n" \
                    'Setting a root password is required for security reasons.'
    @password_field_label = 'New MariaDB root &Password'
  end

  def set_root_password(new_root_password, hostname)
    RMT::Utils.run_command(
      "echo 'SET PASSWORD FOR root@%1=PASSWORD(\"%2\");' | mysql -u root 2>/dev/null",
      hostname,
      new_root_password
    ) == 0
  end
end
