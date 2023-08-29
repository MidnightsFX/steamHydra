require "open-uri"

module SteamHydra
  # Mod manager Interface
  module ModManager
    
    def self.install_or_update_mods(update: true, server_directory: SteamHydra.config[:server_dir])
      if SteamHydra.config[:modded] != true
        LOG.debug("Mods not enabled, not installing any mods.")
      end

      modlist = ENV['Mods'].split(",")

      case SteamHydra.config[:server]
      when 'Valheim'
        resolved_mods = []
        modlist.each do |mod|
          mod_and_version = mod.split("-")
          if mod_and_version.length > 1
            resolved_mods << ModLibrary.thunderstore_check_for_named_mod(mod_and_version[0], mod_and_version[1])
          else
            resolved_mods << ModLibrary.thunderstore_check_for_named_mod(mod_and_version[0])
          end
        end
        ModManager.valheim_install_update_remove_mod(resolved_mods, update, server_directory: server_directory)
      else
        LOG.info("Mod manager not setup to manage mods for #{SteamHydra.config[:server]}")
      end
    end

    def self.valheim_install_update_remove_mod(targeted_mods, update, staging_directory: "#{SteamHydra::FileManipulator.gem_resource_location}steamhydra/cache/modtemp/", server_directory: )
      SteamHydra::FileManipulator.ensure_file(staging_directory, nil, false)
      modprofile = ModManager.check_mod_profile()
      currently_installed = modprofile[:installed]
      mods_to_remove = []
      mods_to_install = []
      mod_dependencies_to_install = []
      mod_dependencies = []

      unless currently_installed.empty?
        modprofile[:installed].each do |mod_entry|
          next if targeted_mods.include?(mod_entry[:name]) || targeted_mods.include?(mod_entry[:full_name])
          mods_to_remove << mod_entry[:name]
        end
      end
      targeted_mods.each do |requested_mod|
        # Mod not yet installed
        if !currently_installed.include?(requested_mod[:name])
          mods_to_install << requested_mod[:name]
          next
        end
        # Mod needs an update
        modprofile[:installed].each do |installed_mod|
          next if installed_mod[:name] != requested_mod[:name]

          if installed_mod[:version] != requested_mod[:target_version]
            mods_to_install << requested_mod[:name]
          end
        end
      end

      mods_to_install.each do |mod_to_install|
        mod_metadata = ModLibrary.thunderstore_check_for_named_mod(mod_to_install)
        mod_metadata[:dependencies].split(",").each do |dep|
          dep_data = dep.split("-")
          next if dep_data[1] == "BepInExPack_Valheim"
          # we should consider how we want to do dependencies version enforcement here
          dep_mod_meta = ModLibrary.thunderstore_check_for_named_mod(dep_data[1])
          mod_dependencies_to_install << dep_mod_meta[:name]
          mod_dependencies << dep_mod_meta
        end
      end
      
      LOG.info("Mod installs Requested: #{mods_to_install}") unless mods_to_install.empty?
      LOG.info("Mod dependencies are required and will also be installed: #{mod_dependencies_to_install}") unless mod_dependencies_to_install.empty?
      LOG.info("Mods no longer managed, being removed: #{mods_to_remove}") unless mods_to_remove.empty?

      LOG.info("Dependency installs started.") unless mod_dependencies_to_install.empty?
      mod_dependencies.each do |mod|
        LOG.info("Starting Mod install: #{mod[:name]}")
        thunderstore_download_mod(mod[:version_download_url],"#{staging_directory}/#{mod[:name]}.zip")
        extract_and_move_mod(staging_directory, mod[:name], server_directory: server_directory)
      end

      LOG.info("Requested Mod installs starting.") unless mods_to_install.empty?
      mods_to_install.each do |mod_to_install|
        targeted_mods.each do |requested_mod|
          next if requested_mod[:name] != mod_to_install

          LOG.info("Starting Mod install: #{requested_mod[:name]}")
          thunderstore_download_mod(requested_mod[:version_download_url],"#{staging_directory}/#{requested_mod[:name]}.zip")
          extract_and_move_mod(staging_directory, requested_mod[:name], server_directory: server_directory)
        end
      end

      # Delete the plugin folders of any mods that are being removed
      mods_to_remove.each do |mod|
        LOG.debug("Removing #{mod}.")
        `rm -rf #{server_directory}BepInEx/plugins/#{mod}`
      end

    end

    def self.check_mod_profile()
      modprofile_file = "#{SteamHydra::FileManipulator.gem_resource_location}/steamhydra/cache/mod_profile.json"
      if !File.exists?(modprofile_file)
        File.new(modprofile_file, "w")
      end
      modprofile = File.read(modprofile_file)
      if modprofile.empty?
        modprofile = { installed: [] }
      else
        modprofile = JSON.parse(modprofile) 
      end
      return modprofile
    end

    def self.thunderstore_download_mod(url, destination_file)
      LOG.debug("Downloading file: #{url}")
      download = URI.open(url)
      IO.copy_stream(download, destination_file)
      LOG.debug("Download complete.")
    end

    def self.extract_and_move_mod(staging_directory, modname, server_directory: SteamHydra.config[:server_dir])
      LOG.debug("unzip -o #{staging_directory}#{modname}.zip")
      status = system("unzip -o #{staging_directory}#{modname}.zip -d #{staging_directory}")
      LOG.debug("Archive unzipped? #{status}.")
      `rm #{staging_directory}#{modname}.zip`
      mod_folder_files = Dir.children(staging_directory)
      FileManipulator.ensure_file("#{server_directory}BepInEx/plugins/#{modname}/" ,nil, false)

      if mod_folder_files.include?("plugins")
        LOG.debug("Copying plugins to BepInEx.")
        `cp -r #{staging_directory}plugins/. #{server_directory}BepInEx/plugins/#{modname}`
      end
      if mod_folder_files.include?("config")
        LOG.debug("Copying configs to BepInEx.")
        `cp -r #{staging_directory}config/. #{server_directory}BepInEx/config`
      end

      LOG.debug("Copying files to modfolder in plugins #{modname}")
      mod_folder_files.each do |file_folder|
        next if file_folder == "plugins" || file_folder == "config"
        `cp -r #{staging_directory}#{file_folder} #{server_directory}BepInEx/plugins/#{modname}/#{file_folder}`
      end

      LOG.debug("#{modname} extraction and move complete. Cleaning folder.")
      `rm -rf #{staging_directory}/*`
    end
  end
end
