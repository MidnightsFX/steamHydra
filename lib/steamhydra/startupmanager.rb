module SteamHydra
  module StartupManager

    def self.set_startup_cmd_by_server_type()
      case SteamHydra.config[:server]
      when 'Valheim'
        SteamHydra.set_cfg_value(:start_server_cmd, StartupManager.build_startup_for_valheim())
      else
        LOG.error("Startup handler not found for this server type. Server type: #{SteamHydra.config[:server]}")
        exit 1
      end
    end

    def self.build_startup_for_valheim()
      command = []
      command << 'LD_LIBRARY_PATH=./linux64:$LD_LIBRARY_PATH'
      command << 'SteamAppId=892970'
      command << './valheim_server.x86_64'
      command << "-name '#{SteamHydra.config[:sessionname]}'"
      command << "-port #{SteamHydra.config[:port]}"
      command << "-world '#{SteamHydra.config[:servermap]}'"
      command << "-password '#{SteamHydra.config[:serverpass]}'"
      # Set the worldsave to be on the locally mounted volume
      command << "-savedir '#{SteamHydra.config[:server_dir]}saves/#{SteamHydra.config[:servermap]}'"
      full_command = command.join(' ')
      LOG.debug("Build Valheim startup command: #{full_command}")
      return full_command
    end

  end
end
