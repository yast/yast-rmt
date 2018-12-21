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

require 'yaml'
require 'shellwords'

Yast.import 'Report'

module RMT; end

class RMT::Utils
  include Yast::Logger
  extend Yast::I18n
  textdomain 'rmt'

  PROTECTED_FILE_PATH = '/etc/rmt/protected_file'.freeze
  CONFIG_FILENAME = '/etc/rmt.conf'.freeze
  DEFAULT_CONFIG = {
    'scc' => {
      'username' => '',
      'password' => ''
    },
    'database' => {
      'host' => 'localhost',
      'database' => 'rmt',
      'username' => 'rmt',
      'password' => ''
    }
  }.freeze

  class << self
    def read_config_file
      begin
        data = Yast::SCR.Read(Yast.path('.target.string'), CONFIG_FILENAME)
        config = YAML.safe_load(data)
      rescue StandardError => e
        log.warn 'Reading config file failed: ' + e.to_s
      end

      ensure_default_values(config)
    end

    def write_config_file(config)
      if Yast::SCR.Write(Yast.path('.target.string'), CONFIG_FILENAME, YAML.dump(config))
        Yast::Popup.Message(_('Configuration written successfully.'))
      else
        Yast::Report.Error(_('Writing configuration file failed. See YaST logs for details.'))
      end

    end

    # Runs a command and returns the exit code
    def run_command(command, *params)
      params = params.map { |p| Shellwords.escape(p) }

      Yast::SCR.Execute(
        Yast.path('.target.bash'),
        Yast::Builtins.sformat(command, *params)
      )
    end

    def create_protected_file(password)
      path = PROTECTED_FILE_PATH + (Random.rand * 1000).round.to_s
      File.open(path, 'w', 0o600) do |file|
        file.write(password)
      end
      path
    end

    def remove_protected_file(path)
      File.delete(path)
    end

    protected

    def ensure_default_values(config)
      config ||= {}
      config.merge(DEFAULT_CONFIG, &method(:merge_hashes))
    end

    def merge_hashes(_, v1, v2)
      if v1.is_a?(Hash)
        v1.merge(v2, &method(:merge_hashes))
      else
        v1 ? v1 : v2
      end
    end
  end
end
