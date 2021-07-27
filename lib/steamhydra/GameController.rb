module SteamHydra
  # Controls gameserver application, delegates for hyper specific requirements
  module GameController
    def self.start_server_thread()
      thr = Thread.new do
        LOG.debug('Starting Server Thread')
        system(SteamHydra.config[:start_server_cmd])
        LOG.debug('Server Thread exited')
      end
      LOG.info("Server Thread #{thr} created.")
      SteamHydra.set_cfg_value(:server_thread, thr)
      return thr
    end
    # Checks for updates for the Game server, returns status based on the update information.
    def self.check_for_server_updates()
      update_status = `#{GameController.build_steamcmd_request("+force_install_dir /server +app_info_update 1 #{SteamHydra.srv_cfg(:id)}")}`
      app_info = false
      status_details = { 'needupdate' => true }
      LOG.debug("Update Output: #{update_status}") if SteamHydra.config[:verbose]
      update_status.split("\n").each do |line|
        if line.include?("#{SteamHydra.srv_cfg(:id)} already up to date.")
          status_details['needupdate'] = false
          break
        end
        # Not sure these are really the correct statuses to be checking for.
        status_details['needupdate'] = false if line.include?("'#{SteamHydra.srv_cfg(:id)}' already up to date.") || line.include?(' update state:  ( No Error )')
        next unless app_info == true || line.empty? || line.include?(' - ')

        if line[0..2] == '   ' && status_details['mounted depots']
          status_details['mounted depots'] += line
          next
        end
        details = line.gsub(' - ', '').split(':')
        status_details[details[0].to_s] = details[1]
      end
      LOG.debug("Update Status for #{SteamHydra.srv_cfg(:name)}: #{status_details}")
      return status_details
    end

    def self.check_players_on_server()
      players = true
      case SteamHydra.config[:server]
      when 'Valheim'
        # check if there are players on the server
        
      else
        LOG.warn("No player check found for: #{SteamHydra.config[:server]} this will result in the check failing")
      end
      return players
    end

    # Install/update &/or validate game install
    # TODO: Check success and fail if game is not installed/updated correctly
    def self.update_install_game(validate = false)
      val_cmd = 'validate' if validate
      cmd = GameController.build_steamcmd_request("+force_install_dir /server +app_update #{SteamHydra.srv_cfg(:id)} #{val_cmd}")
      # TODO: Ensure that game is not running during the update | This should never be true, but we should ensure thats the case...
      LOG.info("Updating #{SteamHydra.srv_cfg(:name)}: #{system(cmd)}")
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
