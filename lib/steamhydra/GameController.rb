module SteamHydra
  # Controls gameserver application, delegates for hyper specific requirements
  module GameController
    def self.start_server_thread()
      thr = Thread.new do
        LOG.debug("Starting Server Thread with: #{SteamHydra.config[:start_server_cmd]}")
        system(SteamHydra.config[:start_server_cmd])
        LOG.debug('Server Thread exited')
      end
      LOG.info("Server Thread #{thr} created.")
      SteamHydra.set_cfg_value(:server_thread, thr)
      sleep 10
      LOG.debug("Server thread #{SteamHydra.config[:server_thread]} alive?: #{SteamHydra.config[:server_thread].alive?}")
      return thr
    end

    # Kills the server thread and checks for any processes hanging around
    def self.stop_server_thread()
      Thread.kill(SteamHydra.config[:server_thread])
      sleep 5
      server_thread_status = SteamHydra.config[:server_thread].alive?
      LOG.debug("Is the server thread alive? #{server_thread_status}")
      sleep 10
      other_processes = `ps h -eo pid,ppid,args`
      LOG.debug("Checking child processes: \n #{other_processes}") if SteamHydra.config[:verbose]
      other_processes.split("\n").each do |entry|
        next if entry.include?('/usr/local/bin/ruby') # don't want to kill the supervisor
        next if entry.include?('ps h -eo pid,ppid,args') # we don't need to try to kill the ps we just requested
        next unless entry.include?('valheim_server.x86_64') # we really just want to interrupt the actual running server

        elements = entry.split(' ')
        LOG.debug("Running: kill -SIGINT #{elements[0]}")
        `kill -SIGINT #{elements[0]}`
      end
      sleep 30
      remaining_processes = `ps -eo pid,ppid,args`
      LOG.debug("Remaining processes: \n #{remaining_processes}") if SteamHydra.config[:verbose]
    end
    # Checks for updates for the Game server, returns status based on the update information.
    def self.check_for_server_updates()
      current_build_info = GameController.get_game_metadata(false)
      status_details = { 'needupdate' => false }
      if current_build_info['buildid'] != SteamHydra.config[:build_id] || current_build_info['timeupdated'] != SteamHydra.config[:build_datetime]
        status_details['needupdate'] = true
        # Since we are performing an update we need to set the current build as what we are now running, so we don't update constantly.
        SteamHydra.set_cfg_value(:build_id, current_build_info['buildid'])
        SteamHydra.set_cfg_value(:build_datetime, current_build_info['timeupdated'])
      end
      LOG.info("Update Status for #{SteamHydra.srv_cfg(:name)}: #{status_details}")
      # This is a 'temp fix' for the newer broken details with recent steamcmd
      # Kill steam error reports -_- which otherwise are zombies...
      # other_processes = `ps h -eo pid,ppid,args`
      # other_processes.split("\n").each do |entry|
      #   next unless entry.include?('steamerrorrepor') # just looking for steamerrorrepor processes
      # 
      #   elements = entry.split(' ')
      #   LOG.debug("Running: kill -SIGINT #{elements[0]}")
      #   `kill -SIGINT #{elements[0]}`
      # end
      return status_details
    end

    def self.get_game_metadata(update_server_stored_data = true)
      url = URI.parse("https://api.steamcmd.net/v1/info/#{SteamHydra.srv_cfg(:id)}")
      req = Net::HTTP::Get.new(url.to_s)
      app_info = Net::HTTP.start(url.host, url.port, use_ssl: true) {|http| http.request(req) }
      LOG.debug("steamcmd api response: #{app_info.code}")
      app_details = JSON.parse(app_info.body)
      # current released build
      current_build = app_details['data']["#{SteamHydra.srv_cfg(:id)}"]['depots']['branches']['public']
      LOG.debug("Retrieved Current Build info: #{current_build}")
      if update_server_stored_data
        SteamHydra.set_cfg_value(:build_id, current_build['buildid'])
        SteamHydra.set_cfg_value(:build_datetime, current_build['timeupdated'])
      end
      return current_build
    end

    # Install/update &/or validate game install
    # TODO: Check success and fail if game is not installed/updated correctly
    def self.update_install_game(validate = false)
      val_cmd = 'validate' if validate
      cmd = GameController.build_steamcmd_request("+force_install_dir /server +app_update #{SteamHydra.srv_cfg(:id)} #{val_cmd}")
      # TODO: Ensure that game is not running during the update | This should never be true, but we should ensure thats the case...
      LOG.debug("Updating #{SteamHydra.srv_cfg(:name)}: #{`#{cmd}`}")
      LOG.info('Updates Completed!')
    end

    def self.build_steamcmd_request(request)
      full_request = []
      full_request << "#{SteamHydra.config[:steamcmd]} +@ShutdownOnFailedCommand 1 +@NoPromptForPassword 1 +login #{SteamHydra.config[:steamuser]}"
      full_request << request.to_s
      full_request << '+quit'
      req = full_request.join(' ')
      LOG.debug("Built request: #{req}")
      return req
    end
  end
end
