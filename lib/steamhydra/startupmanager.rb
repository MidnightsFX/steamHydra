module SteamHydra
  module StartupManager

    def self.set_startup_cmd_by_server_type(_options)
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
      servername = ENV['SessionName'].nil? ? 'SteamHydra Valheim' : ENV['SessionName']
      command << "-name '#{servername}'"
      baseport = ENV['Port'].nil? ? '2456' : ENV['Port']
      command << "-port #{baseport}"
      servermapname = ENV['ServerMap'].nil? ? 'Niflheim' : ENV['ServerMap']
      command << "-world '#{servermapname}'"
      # if ENV['serverPass']
      serverpass = ENV['ServerPass'].nil? ? 'test1234' : ENV['ServerPass']
      command << "-password '#{serverpass}'"
      # Set the worldsave to be on the locally mounted volume
      command << "-savedir '#{SteamHydra.config[:server_dir]}saves/#{servermapname}'"
      full_command = command.join(' ')
      LOG.debug("Build Valheim startup command: #{full_command}")
      return full_command
    end

    # Collect ENV variables arkflag_ & arkarg_
    # Collect configuration defined in [STARTUP_ARGS] ARGS FLAGS
    # def self.build_startup_cmd(provided_configs)
    #   startup_flags = StartupManager.collect_startup_flags(provided_configs)['[startup_flags]']
    #   startup_args = StartupManager.collect_startup_args(provided_configs)['[startup_args]']
    #   # Define the active mods
    #   serversettings = provided_configs.keys.find {|k| k.downcase == '[serversettings]'}
    #   StartupManager.set_mods(provided_configs[serversettings], startup_args) # This also modifies startup args to match mods selected
    #   full_start_cmd = StartupManager.build_server_args(startup_args, startup_flags)
    #   SteamHydra.set_cfg_value(:start_server_cmd, full_start_cmd)
    #   return full_start_cmd
    # end

    # Collects startup FLAGS from the environment and from config files
    def self.collect_startup_flags(provided_configs)
      startup_flags_key = provided_configs.keys.find {|k|  k.downcase == '[startup_flags]'}
      startup_flags_env = ConfigGen.build_cfg_from_envs('arkflag_', '[startup_flags]')
      startup_flags_provided = Util.hash_select(provided_configs, startup_flags_key)
      startup_flags = ConfigLoader.merge_configs(startup_flags_env, startup_flags_provided)
      ConfigGen.remove_blanks!(startup_flags[startup_flags_key]['content'])
      LOG.debug("Collected Startup FLAGS: #{startup_flags}")
      return startup_flags
    end

    # Collects startup ARGS from the environment and from config files
    def self.collect_startup_args(provided_configs)
      startup_args_key = provided_configs.keys.find {|k|  k.downcase == '[startup_args]'}
      startup_args_env = ConfigGen.build_cfg_from_envs('arkarg_', '[startup_args]')
      startup_args_provided = Util.hash_select(provided_configs, startup_args_key)
      startup_args = ConfigLoader.merge_configs(startup_args_env, startup_args_provided)
      ConfigGen.remove_blanks!(startup_args)
      LOG.debug("Collected Startup ARGS: #{startup_args}")
      return startup_args
    end

    def self.build_server_args(args, flags)
      LOG.debug('Building server start command')
      startup_flags = []
      startup_args = [SteamHydra.config['map'], 'listen', "SessionName=#{SteamHydra.config['sessionname']}"]
      args['content'].each do |arg|
        startup_args << if arg[1].empty?
                          arg[0] # Support for non-key-value entries like 'listen'
                        else
                          arg.join('=')
                        end
      end
      ConfigGen.remove_blanks!(startup_args)
      LOG.debug("Startup Args: #{startup_args}")
      flags['content'].each do |flag|
        startup_flags << if flag[1].empty?
                           "-#{flag[0]}"
                         else
                           "-#{flag.join('=')}" # Support key-valued flags
                         end
      end
      ConfigGen.remove_blanks!(startup_flags)
      LOG.debug("Startup Flags: #{startup_flags}")

      startup_command = "/server/ShooterGame/Binaries/Linux/ShooterGameServer #{startup_args.join('?')} #{startup_flags.join(' ')}"
      LOG.info("Built Startup Command: #{startup_command}")
      return startup_command
    end

    def self.set_mods(provided_configuration, startup_args)
      mods = ''
      if startup_args['keys'].include?('GameModIds')
        LOG.debug('Found mods in startup arguments, selecting them.')
        mods = Utils.arr_select(startup_args['content'], 'GameModIds')[0][1]
        LOG.debug("Logs set to: #{mods}")
      end
      if provided_configuration
        if provided_configuration['keys'].include?('ActiveMods')
          LOG.debug('Found ActiveMods config, setting mods')
          mods_source2 = Utils.arr_select(provided_configuration['content'], 'ActiveMods')[0][1]
          mods += mods_source2 unless mods_source2.empty?
        end
      end
      mods = ENV['mods'] if ENV['mods'] # In this case, like most others environment wins
      u_mods = if mods.nil? && !SteamHydra.config[:mods].nil?
                 SteamHydra.config[:mods].uniq
               else
                 mods.split(',').uniq
               end
      LOG.debug("Setting mods to: #{u_mods}")
      SteamHydra.set_cfg_value(:mods, u_mods)
      SteamHydra.set_cfg_value(:mods, []) if u_mods.empty?

      unless SteamHydra.config[:mods].nil?
        unless SteamHydra.config[:mods].empty?
          startup_args['content'] << ['GameModIds', SteamHydra.config[:mods].join(',')]
          startup_args['keys'] << 'GameModIds'
        end
      end
    end

    def self.start_server_ensure_running()

    end
  end
end
