require "open-uri"

module SteamHydra
  # Mod manager Interface
  module ModManager
    
    def self.install_or_update_mods(update: true, server_directory: SteamHydra.config[:server_dir])
      if SteamHydra.config[:modded] != true
        LOG.debug("Mods not enabled, not installing any mods.")
      end
      if ENV['Mods'].nil?
        LOG.info("No mods set, skipping mod install.")
        return
      end

      modlist = ENV['Mods'].split(",")

      case SteamHydra.config[:server]
      when 'Valheim'
        resolved_mods = []
        modlist.each do |mod|
          mod_and_version = mod.split("+")
          mod_result = nil
          if mod_and_version.length > 1
            mod_result = ModLibrary.thunderstore_check_for_named_mod(mod_and_version[0], version: mod_and_version[1])
          else
            mod_result = ModLibrary.thunderstore_check_for_named_mod(mod_and_version[0])
          end
          if mod_result.nil?
            LOG.warn("#{mod_and_version[0]} search did not result in any mods, skipping to next mod.")
            next
          end
          resolved_mods << mod_result
        end
        ModManager.valheim_install_update_remove_mod(resolved_mods, update, server_directory: server_directory)
      else
        LOG.info("Mod manager not setup to manage mods for #{SteamHydra.config[:server]}")
      end
    end

    def self.valheim_install_update_remove_mod(targeted_mods, update, staging_directory: "#{SteamHydra::FileManipulator.gem_resource_location}steamhydra/cache/modtemp", server_directory: )
      SteamHydra::FileManipulator.ensure_file(staging_directory, nil, false)
      modprofile = ModManager.check_mod_profile(modprofile_directory: server_directory)
      currently_installed = modprofile[:installed]
      mods_to_remove = []
      mods_to_install = []
      mod_dependencies_to_install = []
      mod_dependencies = []

      targeted_mods.each do |requested_mod|
        # Mod not yet installed
        mod_already_installed = false
        currently_installed.each do |installed_mod|
          name_match = installed_mod[:name] == requested_mod[:name]
          full_name_match = installed_mod[:full_name] == requested_mod[:full_name]
          mod_already_installed = true if name_match || full_name_match
        end
        mods_to_install << requested_mod[:name] if mod_already_installed == false
        # Mod needs an update
        modprofile[:installed].each do |installed_mod|
          next if installed_mod[:name] != requested_mod[:name]

          if installed_mod[:version] != requested_mod[:target_version]
            mods_to_install << requested_mod[:name]
          end
        end
      end

      # We always want to lookup dependencies for managed mods, incase they change and since they are not tracked elsewhere
      targeted_mods.each do |target_mod|
        mod_metadata = ModLibrary.thunderstore_check_for_named_mod(target_mod[:full_name])
        mod_metadata[:dependencies].split(",").each do |dep|
          dep_data = dep.split("-")
          next if dep_data[1] == "BepInExPack_Valheim"

          LOG.info("Checking for requested dependency mod: #{dep_data[0]}-#{dep_data[1]}")
          # we should consider how we want to do dependencies version enforcement here
          dep_mod_meta = ModLibrary.thunderstore_check_for_named_mod_by_author(dep_data[1], dep_data[0])
          mod_dependencies << dep_mod_meta
          mod_dependency_already_installed = false
          currently_installed.each do |installed_mod|
            name_match = installed_mod[:name] == dep_mod_meta[:name]
            full_name_match = installed_mod[:full_name] == dep_mod_meta[:full_name]
            mod_dependency_already_installed = true if name_match || full_name_match
          end
          next if mod_dependency_already_installed == true
          mod_dependencies_to_install << dep_mod_meta[:name]

        end
      end

      unless currently_installed.empty?
        modprofile[:installed].each do |mod_entry|
          keep_mod = false
          # Don't remove requested mods
          targeted_mods.each do |target_mod_entry|
            name_match = target_mod_entry[:name] == mod_entry[:name]
            full_name_match = target_mod_entry[:full_name] == mod_entry[:full_name]
            keep_mod = true if name_match || full_name_match
          end
          # Don't remove dependencies that are required
          # This does mean that if a mod removes a dependency it will be removed here.
          mod_dependencies.each do |dep_mod|
            name_match = dep_mod[:name] == mod_entry[:name]
            full_name_match = dep_mod[:full_name] == mod_entry[:full_name]
            keep_mod = true if name_match || full_name_match
          end
          next if keep_mod == true

          mods_to_remove << mod_entry[:name]
        end
      end
      
      LOG.info("Mod installs Requested: #{mods_to_install}") unless mods_to_install.empty?
      LOG.info("Mod dependencies are required and will also be installed: #{mod_dependencies_to_install}") unless mod_dependencies_to_install.empty?
      LOG.info("Mods no longer managed, being removed: #{mods_to_remove}") unless mods_to_remove.empty?

      unless mod_dependencies_to_install.empty?
        LOG.info("Dependency installs started.")
        mod_dependencies.each do |mod|
          LOG.info("Starting Mod install: #{mod[:name]}")
          thunderstore_download_mod(mod[:version_download_url],"#{staging_directory}/#{mod[:name]}.zip")
          extract_and_move_mod(staging_directory, mod[:name], server_directory: server_directory)
          modprofile[:installed] << { name: mod[:name], version: mod[:target_version], full_name: mod[:full_name] }
        end
      end

      LOG.info("Requested Mod installs starting.") unless mods_to_install.empty?
      mods_to_install.each do |mod_to_install|
        targeted_mods.each do |requested_mod|
          next if requested_mod[:name] != mod_to_install

          LOG.info("Starting Mod install: #{requested_mod[:name]}")
          thunderstore_download_mod(requested_mod[:version_download_url],"#{staging_directory}/#{requested_mod[:name]}.zip")
          extract_and_move_mod(staging_directory, requested_mod[:name], server_directory: server_directory)
          modprofile[:installed] << { name: requested_mod[:name], version: requested_mod[:target_version], full_name: requested_mod[:full_name] }
        end
      end

      # Delete the plugin folders of any mods that are being removed
      unless mods_to_remove.empty?
        LOG.info("Removing mods unmanaged mods.")
        mods_to_remove.each do |mod|
          LOG.debug("Removing #{mod}.")
          `rm -rf #{server_directory}BepInEx/plugins/#{mod}`
          modprofile[:installed].delete_if {|m| m[:name] == mod}
        end
      end

      # Write out all of the mod profile changes so we know the current state of things for next time- regardless of container status
      ModManager.update_mod_profile(modprofile, modprofile_directory: server_directory)

    end

    def self.check_mod_profile(modprofile_directory: SteamHydra.config[:server_dir])
      if !File.exist?("#{modprofile_directory}mod_profile.json")
        File.new("#{modprofile_directory}mod_profile.json", "w")
      end
      modprofile = File.read("#{modprofile_directory}mod_profile.json")
      if modprofile.empty?
        modprofile = { installed: [] }
      else
        modprofile = JSON.parse(modprofile, symbolize_names: true)
      end
      LOG.debug("returning modprofile: #{modprofile}")
      return modprofile
    end

    def self.update_mod_profile(mod_profile_data, modprofile_directory: SteamHydra.config[:server_dir])
      current_install_metadata = {}
      mod_profile_data[:installed].each do |entry|
        # we always take the key because the newest versions are always listed at the bottom
        current_install_metadata[entry[:name]] = entry
      end
      mod_profile_data[:installed] = []
      current_install_metadata.each do |key, value|
        mod_profile_data[:installed] << value
      end

      File.write("#{modprofile_directory}mod_profile.json", JSON.pretty_generate(mod_profile_data))
    end

    def self.updates_available_from_mod_profile(modprofile_directory: SteamHydra.config[:server_dir])
      return if !File.exist?("#{modprofile_directory}mod_profile.json")
      # bail if there is no mod profile to base updates on

      modprofile = JSON.parse(File.read("#{modprofile_directory}mod_profile.json"), symbolize_names: true)
      updates_available = false
      modprofile[:installed].each do |mod|
        moddb = ModLibrary.thunderstore_check_for_named_mod(mod[:full_name])
        updates_available = true if mod[:version] != moddb[:target_version]
      end
      return updates_available
    end

    def self.thunderstore_download_mod(url, destination_file)
      LOG.debug("Downloading file: #{url} to #{destination_file}")
      download = URI.open(url)
      IO.copy_stream(download, destination_file)
      LOG.debug("Download complete.")
    end

    def self.extract_and_move_mod(staging_directory, modname, server_directory: SteamHydra.config[:server_dir])
      LOG.debug("unzip -o #{staging_directory}/#{modname}.zip")
      status = system("unzip -o #{staging_directory}/#{modname}.zip -d #{staging_directory}")
      LOG.debug("Archive unzipped? #{status}.")
      `rm #{staging_directory}/#{modname}.zip`
      mod_folder_files = Dir.children(staging_directory)
      FileManipulator.ensure_file("#{server_directory}BepInEx/plugins/#{modname}" ,nil, false)

      if mod_folder_files.include?("plugins")
        LOG.debug("Copying plugins to BepInEx.")
        `cp -r #{staging_directory}/plugins/ #{server_directory}BepInEx/plugins/#{modname}`
      end
      if mod_folder_files.include?("config")
        LOG.debug("Copying configs to BepInEx.")
        `cp -r #{staging_directory}/config/ #{server_directory}BepInEx/config`
      end

      LOG.debug("Copying files to modfolder in plugins #{modname}")
      mod_folder_files.each do |file_folder|
        next if file_folder == "plugins" || file_folder == "config"
        `cp -r #{staging_directory}/#{file_folder} #{server_directory}BepInEx/plugins/#{modname}/#{file_folder}`
      end

      LOG.debug("#{modname} extraction and move complete. Cleaning folder.")
      `rm -rf #{staging_directory}/*`
    end
  end
end
