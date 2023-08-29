module SteamHydra
  module FileManipulator

    # returns the file location of the parent steamhydra folder, allowing gem local file navigation with absolute path
    def self.gem_resource_location()
      return __dir__[0..-11]
    end

    # walks the filepath and if there is no file/folder there it will generate them, does nothing if they exist
    def self.ensure_file(location, filename = nil, enfore_permissions = true)
      LOG.debug("Ensuring File/Folder: #{location}/#{filename}")
      ug_info = File.stat('/steamcmd') if enfore_permissions # Not sure the owner/group is going to always be correct for this
      folder_location = '/'
      location.split('/').each do |segment|
        next if segment == '' # skip start or end slashes

        folder_location = folder_location + segment + '/'
        next if Dir.exist?(folder_location) # do nothing if this folder exists

        Dir.mkdir(folder_location)
        File.chown(ug_info.uid, ug_info.gid, folder_location) if enfore_permissions
      end
      if filename
        # If the file does not exist make a blank one. This is primarily for first gen, when nothing exists
        unless File.exist?(location + '/' + filename)
          File.new(location + '/' + filename, 'w')
          File.chown(ug_info.uid, ug_info.gid, location + '/' + filename) if enfore_permissions
        end
      end
    end

    # Installs the required modding tools based on server type
    def self.install_modtools()
      LOG.info('Ensuring Modtools Installed.')
      case SteamHydra.config[:server]
      when 'Valheim'
        bepInExPack_metadata = ModLibrary.thunderstore_check_for_named_mod("BepInExPack_Valheim", SteamHydra.config[:modded_metadata][:bepinex])
        return if File.exist?("#{SteamHydra.config[:server_dir]}modloader-#{bepInExPack_metadata[:target_version]}.zip")


        bepInExPack_metadata[:version_download_url]

        LOG.debug("Starting download of BapInEx #{SteamHydra.config[:modded_metadata][:bepinex]}")
        LOG.debug("Looking for BepInEx: #{bepInExPack_metadata[:version_download_url]}")
        `curl -sqL "#{bepInExPack_metadata[:version_download_url]}" -o modloader-#{bepInExPack_metadata[:target_version]}.zip`
        `unzip -o modloader-#{bepInExPack_metadata[:target_version]}.zip`
        LOG.debug('Copying BepInEx files to correct locations.')
        `cp -r /server/BepInExPack_Valheim/. /server/` # this depends on the current packaging format of denikson/BepInExPack_Valheim
      else
        LOG.warn("No modloader definition found for gameserver type: #{SteamHydra.config[:server]}")
      end
    end

    # Valdiate gamefiles and modfiles
    def self.validate_gamefiles(validate_status)
      return false unless validate_status

      LOG.info('Validating gamefiles and mods, this can take a while.')
      GameController.update_install_game(true) # update/install & validate game install
      # GameController.check_mods_and_update(true) # update & validate Mods
    end

    def self.install_server(validate: false)
      installed_content = SUPPORTED_SERVERS[SteamHydra.config[:server].to_sym][:install_location]
      # Need to check if the install directories are empty first off | /server/valheim_server_Data
      LOG.debug("Checking server install: #{SteamHydra.config[:server_dir]}#{installed_content}/ #{File.directory?("#{SteamHydra.config[:server_dir]}#{installed_content}/")}")
      if File.directory?("#{SteamHydra.config[:server_dir]}#{installed_content}/")
        LOG.info("#{SteamHydra.config[:server]} directories already present, skipping install.")
        return false
      end
      # Ensure directory permissions are OK to install as steam
      LOG.info("Starting install/Update for #{SteamHydra.config[:server]}.")
      GameController.update_install_game(validate)
      LOG.info("#{SteamHydra.config[:server]} install completed.")
      return true
    end
  end
end
