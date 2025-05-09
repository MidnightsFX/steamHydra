module SteamHydra
  # Supervise the running of the game server
  module Supervisor
    def self.main_loop(options)
     # begin
        # Ingest Configuration - not implemented here again
        # provided_configs = { 'key' => 'value' } # placeholder, we don't ingest configs yet
        # provided_configs = ConfigLoader.discover_configurations('/config')

        # Check if there is a game server installation already
        new_server_status = FileManipulator.install_server()
        if SteamHydra.config[:modded]
          LOG.info('Mods enabled!')
          FileManipulator.install_modtools()
        end
        # Generate Game configurations

        # gameuser_cfg = ConfigGen.gen_game_user_conf(CFG_PATH, provided_configs)
        # ConfigGen.gen_game_conf(CFG_PATH, provided_configs) # Also gen game.conf
        # ConfigGen.set_ark_globals(gameuser_cfg)

        # Handle Validation CLI option
        FileManipulator.validate_gamefiles(SteamHydra.config[:validate])
        # GameController.get_game_metadata()

        # Manage mods to be installed/removed
        if SteamHydra.config[:update_mods_on_start]
          ModLibrary.populate_game_mod_library(SteamHydra.config[:server].downcase.to_sym, true)
        end
        ModManager.install_or_update_mods()

        # Build startup command
        FileManipulator.ensure_file("#{SteamHydra.config[:server_dir]}/logs" ,nil, false)
        StartupManager.set_startup_cmd_by_server_type()
        
        # start service
        # check if update is available
        #  - wait until server is idle to update
        Supervisor.run_server(new_server_status, logstatus: options[:showstatus], sleep_duration: options[:status_interval])
     # rescue StandardError => e
     #   LOG.error("Encounted Runtime Error: #{e.message}")
     #   trace = e.backtrace.join("\n")
     #   LOG.error("Trace: #{trace}")
     # end
    end

    # Loops running the server process
    def self.run_server(new_server_status, logstatus: true, sleep_duration: 30)
      LOG.debug('Starting server monitoring loop')
      Supervisor.first_run(new_server_status) # this will check for server updates
      GameController.start_server_thread()
      start_time = Time.now.to_i
      loop do
        60.times do
          sleep sleep_duration
          status = 'Checking server thread '
          status += "#{SteamHydra.config[:server_thread]} " if SteamHydra.config[:verbose] == true
          
          pid_status = `ps h -o pid,ppid,args #{SteamHydra.config[:server_pid]}`
          server_alive = !pid_status.empty?
          LOG.debug("#{status}livliness: #{SteamHydra.config[:server_thread].alive?} pid_status: #{pid_status}") if logstatus
          next if server_alive # the server pid still running is perhaphs the most important here, if the parent thread dies- thats ok. If both are dead, its a failure scenario.
          next if SteamHydra.config[:server_thread].alive?
          LOG.warn("Could not find server thread running or pid. #{pid_status}}")

          if SteamHydra.config[:auto_restart]
            SteamHydra.config[:server_failures] += 1
            raise('Repeated server failures detected, killing the monitor process. Ensure your server configs are allowing the server to startup correctly.') if SteamHydra.config[:server_failures] == 10

            GameController.start_server_thread()
            sleep 30
          end
        end
        Supervisor.runtime_maintenance()
        Supervisor.update_strategy()
        Supervisor.nightly_restarts(start_time)
      end
    end

    def self.nightly_restarts(start_time)
      if Time.now.to_i > start_time + 86400
        loop do
          break if SteamQueries.check_for_active_players() == false

          sleep 120
        end
        LOG.info('Server detected as empty, restarting the server.')
        GameController.stop_server_thread()
        sleep 30
        GameController.start_server_thread()
        start_time = Time.now.to_i
      end
    end

    def self.update_strategy()
      LOG.debug("Running update strategy check for #{SteamHydra.config[:server]}")
      case SteamHydra.config[:server]
      when 'Valheim'
        # Check for players and update when empty
        update_status = GameController.check_for_server_updates()
        return true if update_status[:server_update] == false && update_status[:mod_updates] == false

        LOG.info('Update found, waiting for the server to empty.')
        loop do
          break if SteamQueries.check_for_active_players() == false

          sleep 120
        end
        LOG.info('Server detected as empty, stopping the server and performing the update.')
        GameController.stop_server_thread()
        if update_status[:server_update]
          GameController.update_install_game(true)
        end
        ModManager.install_or_update_mods()
        GameController.start_server_thread()
      else
        LOG.warn("No Update strategy was found for: #{SteamHydra.config[:server]}. The supervisor will not automatically update this game.")
      end
    end

    def self.runtime_maintenance()
      LOG.debug("Performing runtime maintenace.")
      case SteamHydra.config[:server]
      when 'Valheim'
        if SteamHydra.config[:modded] == true
        SteamHydra.truncate_log("#{SteamHydra.config[:server_dir]}BepInEx/LogOutput.log", bytesize: 1, rotated_size: 0)
        SteamHydra.truncate_log("#{SteamHydra.config[:server_dir]}logs/valheim.log", bytesize: 1, rotated_size: 0)
        end
      else
        LOG.debug("No maintenance strategy defined for #{SteamHydra.config[:server]}. Logs and other system resouces might overflow.")
      end
    end

    # Run-once check for an update, if an update is available will update and start back up
    def self.check_for_updates(_logstatus: true, firstrun: false, forceupdate: false)
      LOG.debug('Starting Checks for updates.')
      update_status = GameController.check_for_server_updates(firstrun)
      # missing_mods_status = GameController.check_for_missing_mods
      # mod_updates_needed = GameController.check_for_mod_updates
      # LOG.debug("Updates Needed: GameServer-#{update_status['needupdate']} MODS-#{mod_updates_needed} Mods Missing?-#{missing_mods_status}")
      # if !update_status['needupdate'] && !mod_updates_needed && !missing_mods_status
      #   LOG.info('No Update needed.') if logstatus
      #   return false
      # end

      if update_status[:server_update] || forceupdate
        unless firstrun # We don't check players if this is a first run because the server is not up
          # loop do
          #   #server_info = SteamQueries.request_server_a2s_info
          #   #LOG.debug("requesting server information: #{server_info}") if verbose
          #   sleep 10
          # end
          LOG.info("#{SteamHydra.config[:server]} Server needs an update, updating.")
        end
        GameController.update_install_game
      end
      # if mod_updates_needed || missing_mods_status
      #   LOG.info('Mods need an update')
      #   GameController.check_mods_and_update(true)
      # end
      # LOG.info('Starting server back up.')
      # LOG.debug("Server thread starting: #{GamekController.start_arkserver_thread()}")
    end

    def self.first_run(new_server_status)
      LOG.info('Starting server firstrun check')
      if new_server_status
        LOG.info('New Server, installing Game Server and Mods.')
        GameController.update_install_game(true) # update/install & validate Game Server
        # GameController.check_mods_and_update(true) # update & validate Mods
      end
      # LOG.info(srv_status.to_s)
      # Implement server status check
      # GameController.check_mods_and_update(true) if Util.true?(GameController.check_for_missing_mods)
      # Check for game update before starting, this will cause updates if needed
      Supervisor.check_for_updates(firstrun: true) # setting first run to skip player checks, and ensure checks for update
      # TODO: setup a backoff for server restart, and integrate discord messaging on failures
      # LOG.info('Starting server.')
      # start_server = GameController.start_server_thread()
      # sleep 500
      # TODO: Loop until the server is running
      # Arkswarm.connect_to_rcon()
      # return start_server
    end
  end
end
