module SteamHydra
  module StartupManager

    def self.set_startup_cmd_by_server_type()
      case SteamHydra.config[:server]
      when 'Valheim'
        StartupManager.ensure_valheim_startup_files()
        StartupManager.build_startup_for_valheim()
        StartupManager.set_runtime_envs()
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
      runtime_env = []
      runtime_env << 'SteamAppId=892970'
      runtime_env << 'LD_LIBRARY_PATH=./linux64:$LD_LIBRARY_PATH'
      if SteamHydra.config[:modded]
        runtime_env << 'DOORSTOP_ENABLE=TRUE'
        runtime_env << 'DOORSTOP_INVOKE_DLL_PATH="${PWD}/BepInEx/core/BepInEx.Preloader.dll"'
        runtime_env << 'DOORSTOP_CORLIB_OVERRIDE_PATH=./unstripped_corlib'
        runtime_env << 'LD_LIBRARY_PATH="${PWD}/doorstop_libs":${LD_LIBRARY_PATH}'
        runtime_env << 'LD_PRELOAD=libdoorstop_x64.so:$LD_PRELOAD'
        runtime_env << 'DYLD_LIBRARY_PATH="${PWD}/doorstop_libs"'
        runtime_env << 'DYLD_INSERT_LIBRARIES="${PWD}/doorstop_libs/libdoorstop_x64.so"'
      end
      command = []
      command << './valheim_server.x86_64'
      command << "-name \"#{SteamHydra.config[:sessionname]}\""
      command << "-password \"#{SteamHydra.config[:serverpass]}\""
      command << "-port \"#{SteamHydra.config[:port]}\""
      command << "-world \"#{SteamHydra.config[:servermap]}\""
      command << "-savedir \"#{SteamHydra.config[:server_dir]}saves/#{SteamHydra.config[:servermap]}\""
      full_command = command.join(' ')
      LOG.debug("Built Valheim startup command: #{full_command}")
      LOG.debug("Built Valheim runtime environment variables: #{runtime_env}")
      SteamHydra.set_cfg_value(:server_runtime_envs, runtime_env)
      SteamHydra.set_cfg_value(:start_server_cmd, full_command)
    end

    # Sets runtime environment variables for the configuration used for this container. This is normally only done once.
    def self.set_runtime_envs()
      SteamHydra.config[:server_runtime_envs].each do |env_var|
        split_var = env_var.split('=')
        ENV[split_var[0]] = split_var[1]
      end
    end

  end
end
