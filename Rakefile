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

require 'yast/rake'

Yast::Tasks.configuration do |conf|
  # The package does not live in the official YaST:Head OBS project
  conf.obs_project = 'systemsmanagement:SCC:RMT'
  # Default target for osc:build
  conf.obs_target = 'openSUSE_Factory'
  conf.skip_license_check = [ %r{^Gemfile\.lock$} ]
end

# This is required, because `yast-travis-ruby` binary calls `rake test:unit`
desc 'Run rspec'
task 'test:unit' do
  sh 'rspec'
end
