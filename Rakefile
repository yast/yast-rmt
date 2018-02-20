require 'yast/rake'

Yast::Tasks.configuration do |conf|
  # The package does not live in the official YaST:Head OBS project
  conf.obs_project = 'systemsmanagement:SCC:RMT'
  # Default target for osc:build
  conf.obs_target = 'openSUSE_Factory'
  conf.skip_license_check = [ %r{^Gemfile\.lock$} ]
end
