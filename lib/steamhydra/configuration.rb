require 'logger'

module SteamHydra
  # Helps ensure that messages are sent as they are generated not on completion of command
  $stdout.sync = true

  VERSION = '0.1.1'.freeze

  SUPPORTED_SERVERS = {
    Valheim: { id: 896660, install_location: 'valheim_server_Data', name: 'Valheim' }
  }

  LOG = Logger.new($stdout)
  LOG.level = Logger::INFO

  def self.set_debug
    SteamHydra::LOG.level = Logger::DEBUG
  end

  def self.set_verbose
    SteamHydra.set_cfg_value(:verbose, true)
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

  def self.set_defaults()
    # Set default configuration values
    SteamHydra.set_cfg_value(:steamcmd, '/steamcmd/steamcmd.sh')
    SteamHydra.set_cfg_value(:server_dir, '/server/')
    SteamHydra.set_cfg_value(:steamuser, 'Anonymous')
    SteamHydra.set_cfg_value(:verbose, false)
    SteamHydra.set_cfg_value(:modded, false)
    SteamHydra.set_cfg_value(:gem_dir, __dir__[0..-12])
    SteamHydra.set_cfg_value(:server_failures, 0)

    # Default user configurations
    case SteamHydra.config[:server]
    when 'Valheim'
      port = ENV['Port'].nil? ? 2456 : ENV['Port'].to_i
      SteamHydra.set_cfg_value(:port, port)
      servermap = ENV['ServerMap'].nil? ? 'Niflheim' : ENV['ServerMap']
      SteamHydra.set_cfg_value(:servermap, servermap)
      if ENV['EnableMods']
        if ENV['EnableMods'].casecmp('true').zero?
          LOG.debug('Mods Enabled.')
          SteamHydra.set_cfg_value(:modded, true)
          SteamHydra.set_cfg_value(:modded_metadata, { bepinex: '5.4.1903' })
          SteamHydra.config[:modded_metadata][:bepinex] = ENV['Modloader'].strip unless ENV['Modloader'].nil?
          # Set modlist here
        end
      end
      SteamHydra.set_cfg_value(:public, 1)
      if ENV['Public']
        listgame = ENV['Public'].to_i.zero? || ENV['Public'].downcase == 'false' ? 0 : 1
        SteamHydra.set_cfg_value(:public, listgame)
      end
    else
      LOG.warn("Defaults not set for this server type. Server type: #{SteamHydra.config[:server]}")
    end
    session = ENV['SessionName'].nil? ? 'SteamHydra' : ENV['SessionName']
    SteamHydra.set_cfg_value(:sessionname, session)
    serverpass = ENV['ServerPass'].nil? ? 'test1234' : ENV['ServerPass']
    SteamHydra.set_cfg_value(:serverpass, serverpass)
  end
end
