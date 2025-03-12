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
require 'rmt/shared/input_password_dialog'
require 'ui/dialog'

module RMT; end
module RMT::MariaDB; end

class RMT::MariaDB::CurrentRootPasswordDialog < RMT::Shared::InputPasswordDialog
  def initialize
    textdomain 'rmt'
    super

    @dialog_heading = _('Database root password is required')
    @dialog_label = _('In order to setup RMT, database access is required. Please provide the current database root password.')
    @password_field_label = _('MariaDB root &password')
  end

  private

  def password_valid?(password)
    root_pw_file = RMT::Utils.create_protected_file("[client]\npassword=#{password}\n")
    begin
      result = RMT::Utils.run_command(
        "echo 'show databases;' | mysql --defaults-extra-file=#{root_pw_file} -u root 2>/dev/null"
      ) == 0
    ensure
      RMT::Utils.remove_protected_file(root_pw_file)
    end
    result
  end
end
