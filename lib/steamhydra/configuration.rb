require 'logger'

module SteamHydra
  # Helps ensure that messages are sent as they are generated not on completion of command
  $stdout.sync = true

  VERSION = '0.1.0'.freeze

  SUPPORTED_SERVERS = {
    Valheim: { id: 896660, install_location: 'valheim_server_Data', name: 'Valhiem'}
  }

  LOG = Logger.new($stdout)
  LOG.level = Logger::INFO

  def self.set_debug
    SteamHydra::LOG.level = Logger::DEBUG
  end

  # For testing purposes, no logging
  def self.set_fatal
    SteamHydra::LOG.level = Logger::FATAL
  end

  @config = {}
  def self.config
    return @config
  end

  def self.set_cfg_value(key, value)
    @config[key] = value
  end

  def self.check_and_set_server(server)
    if SUPPORTED_SERVERS.key?(server.capitalize.to_sym)
      SteamHydra.set_cfg_value(:server, server.capitalize)
      LOG.info("Set server type to: #{server.capitalize}")
    else
      LOG.error("Unsuppored server type provided (#{server.capitalize}), please select a supported server: #{SUPPORTED_SERVERS.keys}")
      exit 1
    end
  end

  def self.srv_cfg(key)
    return SUPPORTED_SERVERS[SteamHydra.config[:server].to_sym][key.to_sym]
  end

  # Set default configuration values
  SteamHydra.set_cfg_value(:steamcmd, '/steamcmd/steamcmd.sh')
  SteamHydra.set_cfg_value(:server_dir, '/server/')
  SteamHydra.set_cfg_value(:steamuser, 'Anonymous')
end
