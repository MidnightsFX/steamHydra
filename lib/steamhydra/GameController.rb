module SteamHydra
  # Controls gameserver application, delegates for hyper specific requirements
  module GameController
    def self.start_server_thread()
      LOG.debug("Starting Server with: #{SteamHydra.config[:start_server_cmd]}")
      thread = Thread.new {
        system("#{SteamHydra.config[:start_server_cmd]}")
        LOG.info("Server Parent thread exiting.")
      }
      sleep 10
      SteamHydra.set_cfg_value(:server_thread, thread)
      running_processes = `ps h -eo pid,ppid,args`
      pid = nil
      LOG.debug("Checking processes: \n #{running_processes}") if SteamHydra.config[:verbose]
      running_processes.split("\n").each do |entry|
        next if entry.include?('/usr/local/bin/ruby') # don't want to kill the supervisor
        next if entry.include?('ps h -eo pid,ppid,args') # we don't need to try to kill the ps we just requested
        next unless entry.include?('valheim_server.x86_64') # we really just want the actual running server

        elements = entry.split(' ')
        LOG.debug("Valheim Server PID: #{elements[0]}")
        pid = elements[0]
      end
      LOG.info("Server pid #{pid}")
      LOG.error("Server pid not detected, server not running.") if pid.nil?
      set_server_pid(pid)
      return pid
    end

    def self.set_server_pid(pid)
      LOG.debug("Setting server pid #{pid} setting file #{SteamHydra.config[:server_dir]}server_pid")
      SteamHydra.set_cfg_value(:server_pid, pid)
      File.write("#{SteamHydra.config[:server_dir]}server_pid", "#{pid}")
    end

    # Kills the server thread and checks for any processes hanging around
    def self.stop_server_thread()
      pid_status = `ps h -o pid,ppid,args #{SteamHydra.config[:server_pid]}`
      server_alive = !pid_status.empty?
      LOG.debug("Is the server thread alive? #{server_alive}")
      kp1 = "kill -s SIGINT #{SteamHydra.config[:server_pid]}"
      `#{kp1}`
      sleep 180
      pid = `cat /server/server_pid`
      kp2 = "kill -s SIGINT #{pid}"
      `#{kp2}`
      Thread.kill(SteamHydra.config[:server_thread])
      remaining_processes = `ps -eo pid,ppid,args`
      LOG.debug("Remaining processes: \n #{remaining_processes}") if SteamHydra.config[:verbose]
    end

    # Checks for updates for the Game server, returns status based on the update information.
    def self.check_for_server_updates(startup = false)
      if startup && SteamHydra.config[:update_mods_on_start] == false
        LOG.info("Skipping first mod update check.")
        return
      end

      current_build_info = GameController.get_game_metadata(false)
      load_game_metadata_from_local_cache()
      status_details = { server_update: false, mod_updates: false }
      if current_build_info['buildid'] != SteamHydra.config[:build_id] || current_build_info['timeupdated'] != SteamHydra.config[:build_datetime]
        status_details[:server_update] = true
        # Since we are performing an update we need to set the current build as what we are now running, so we don't update constantly.
        SteamHydra.set_cfg_value(:build_id, current_build_info['buildid'])
        SteamHydra.set_cfg_value(:build_datetime, current_build_info['timeupdated'])
        write_game_metadata_to_local_cache(current_build_info)
      end
      
      if SteamHydra.config[:modded] == true 
        # This updates the all available mod metadata from thunderstore
        ModLibrary.populate_game_mod_library(:valheim, true)
        status_details[:mod_updates] = ModManager.updates_available_from_mod_profile
      end
      LOG.info("Update Status for #{SteamHydra.srv_cfg(:name)}: #{status_details}")
      return status_details
    end

    def self.write_game_metadata_to_local_cache(current_game_metadata)
      game_metadata_file_location = "#{SteamHydra::FileManipulator.gem_resource_location}steamhydra/cache/#{SteamHydra.config[:server]}_metadata.json}"
      File.write(game_metadata_file_location, JSON.pretty_generate(current_game_metadata))
    end

    def self.load_game_metadata_from_local_cache()
      game_metadata_file_location = "#{SteamHydra::FileManipulator.gem_resource_location}steamhydra/cache/#{SteamHydra.config[:server]}_metadata.json}"
       return if !File.exist?(game_metadata_file_location)
      modprofile = File.read(game_metadata_file_location)
      json_game_metadata = JSON.parse(modprofile)
      SteamHydra.set_cfg_value(:build_id, json_game_metadata['buildid'])
      SteamHydra.set_cfg_value(:build_datetime, json_game_metadata['timeupdated'])
      return json_game_metadata
    end

    def self.get_game_metadata(update_server_stored_data = true)
      current_build = {}
      begin
        steam_resp = Request.make(
          host: 'https://api.steamcmd.net',
          path: "/v1/info/#{SteamHydra.srv_cfg(:id)}",
          headers: { "Content-Type" => "application/x-www-form-urlencoded" },
          method: :get
        )
        raise('bad response from server') if steam_resp[:status] != 200

        app_details = JSON.parse(steam_resp[:body])
        current_build = app_details['data'][SteamHydra.srv_cfg(:id).to_s]['depots']['branches']['public']
        LOG.debug("Retrieved Current Build info: #{current_build}")
        if update_server_stored_data
          SteamHydra.set_cfg_value(:build_id, current_build['buildid'])
          SteamHydra.set_cfg_value(:build_datetime, current_build['timeupdated'])
        end
      rescue
        LOG.warn('Bad response from steam API server, using existing build data for update checking. No Update will occur.')
        current_build = {
          'buildid' => SteamHydra.config[:build_id],
          'timeupdated' => SteamHydra.config[:build_datetime]
        }
      end
      return current_build
    end

    # Install/update &/or validate game install
    # TODO: Check success and fail if game is not installed/updated correctly
    def self.update_install_game(validate = false)
      val_cmd = 'validate' if validate
      cmd = GameController.build_steamcmd_request("+app_update #{SteamHydra.srv_cfg(:id)} #{val_cmd}")
      # TODO: Ensure that game is not running during the update | This should never be true, but we should ensure thats the case...
      LOG.debug("Updating #{SteamHydra.srv_cfg(:name)}: #{`#{cmd}`}")
      LOG.info('Updates Completed!')
    end

    def self.build_steamcmd_request(request)
      full_request = []
      full_request << "#{SteamHydra.config[:steamcmd]} +@sSteamCmdForcePlatformType linux +force_install_dir /server +@ShutdownOnFailedCommand 1 +@NoPromptForPassword 1 +login #{SteamHydra.config[:steamuser]}"
      full_request << request.to_s
      full_request << '+quit'
      req = full_request.join(' ')
      LOG.debug("Built request: #{req}")
      return req
    end
  end
end
