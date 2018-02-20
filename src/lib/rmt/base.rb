require 'yaml'

module RMT
end

class RMT::Base < Yast::Client
  include Yast::UIShortcuts
  include Yast::Logger
  include Yast::I18n

  CONFIG_FILENAME = '/etc/rmt.conf'.freeze

  def self.read_config_file
    begin
      data = Yast::SCR.Read(Yast.path('.target.string'), CONFIG_FILENAME)
      config = YAML.safe_load(data)
    rescue StandardError => e
      log.warn 'Reading config file failed: ' + e.to_s
    end

    config ||= {}
    config['scc'] ||= {}
    config['scc']['username'] ||= ''
    config['scc']['password'] ||= ''

    config['database'] ||= {}
    config['database']['database'] ||= 'rmt'
    config['database']['username'] ||= 'rmt'
    config['database']['password'] ||= ''
    config['database']['hostname'] ||= 'localhost'

    config
  end

  def self.write_config_file(config)
    if Yast::SCR.Write(Yast.path('.target.string'), CONFIG_FILENAME, YAML.dump(config))
      Yast::Popup.Message('Configuration written successfully')
    else
      Report.Error('Writing configuration file failed')
    end

  end

  # Runs a command and returns the exit code
  def run_command(command, *params)
    params = params.map { |p| String.Quote(p) }

    Convert.to_integer(
      SCR.Execute(
        path('.target.bash'),
          Builtins.sformat(command, *params)
      )
    )
  end
end
