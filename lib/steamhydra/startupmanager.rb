module SteamHydra
  module StartupManager

    def self.set_startup_cmd_by_server_type()
      case SteamHydra.config[:server]
      when 'Valheim'
        StartupManager.ensure_valheim_startup_files()
        SteamHydra.set_cfg_value(:start_server_cmd, StartupManager.build_startup_for_valheim())
      else
        LOG.error("Startup handler not found for this server type. Server type: #{SteamHydra.config[:server]}")
        exit 1
      end
    end

    def self.ensure_valheim_startup_files()
      # Remove the files if they exist
      return if File.exist?("#{SteamHydra.config[:server_dir]}valheim_start.sh") && File.exist?("#{SteamHydra.config[:server_dir]}valheim_modded_start.sh")

      FileUtils.rm(["#{SteamHydra.config[:server_dir]}valheim_start.sh", "#{SteamHydra.config[:server_dir]}valheim_modded_start.sh"], force: true)
      # Copy in the current templates
      LOG.debug("Copying new startup templates from: #{SteamHydra.config[:gem_dir]}/config_templates/")
      FileUtils.cp(["#{SteamHydra.config[:gem_dir]}/config_templates/valheim_start.sh"], SteamHydra.config[:server_dir])
      FileUtils.cp(["#{SteamHydra.config[:gem_dir]}/config_templates/valheim_modded_start.sh"], SteamHydra.config[:server_dir])
      if File.exist?("#{SteamHydra.config[:server_dir]}valheim_start.sh") && File.exist?("#{SteamHydra.config[:server_dir]}valheim_modded_start.sh")
        File.chmod(0775, "#{SteamHydra.config[:server_dir]}valheim_start.sh")
        File.chmod(0775, "#{SteamHydra.config[:server_dir]}valheim_modded_start.sh")
      else
        LOG.error('Startup scripts were not found after copy, ensure the user running docker the container has permissions to the server folders.')
        exit 1
      end
    end

    def self.build_startup_for_valheim()
      file = if SteamHydra.config[:modded]
               '/valheim_start.sh'
             else
               '/valheim_modded_start.sh'
             end
      command = []
      command << "SERVERNAME='#{SteamHydra.config[:sessionname]}'"
      command << "PASSWORD='#{SteamHydra.config[:serverpass]}'"
      command << "PORT=#{SteamHydra.config[:port]}"
      command << "WORLDNAME='#{SteamHydra.config[:servermap]}'"
      command << "SAVEDIR='#{SteamHydra.config[:server_dir]}saves/#{SteamHydra.config[:servermap]}'"
      command << ".#{file}"
      full_command = command.join(' ')
      LOG.debug("Build Valheim startup command: #{full_command}")
      return full_command
    end

  end
end
