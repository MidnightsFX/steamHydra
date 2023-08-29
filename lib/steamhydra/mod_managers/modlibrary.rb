require "sqlite3"

module SteamHydra
  # Mod manager Interface
  module ModLibrary

    @mod_db = SQLite3::Database.new "#{SteamHydra::FileManipulator.gem_resource_location}/steamhydra/cache/mod_library.db"

    def self.create_modtables_if_missing()
      unless @mod_db.table_info('valheim_thunderstore').nil?

        tables = @mod_db.execute("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'")
        tables = tables.flatten
        LOG.info("Table Status: #{tables}")

        unless tables.include?("valheim_thunderstore")
          @mod_db.execute <<-SQL
            CREATE TABLE valheim_thunderstore (
              name text,
              owner text,
              full_name text UNIQUE,
              package_url text,
              date_updated text,
              uuid4 text,
              current_version text,
              download_url text,
              dependencies text
            );
          SQL
        end

        ModLibrary.populate_game_mod_library(:valheim)

      end
    end

    def self.populate_game_mod_library(game)

      case game

      when :valheim
        # Valheim currently supports thunderstore so we will use it to manage mods
        modlist = SteamHydra::ThunderstoreAPI.get_available_modlist('valheim')
        modlist.each do |entry|
          ver = entry["versions"][0]["version_number"]
          download_url = entry["versions"][0]["download_url"].gsub("/#{ver}/","")
          dependencies = entry["versions"][0]["dependencies"].join(",")
          # Insert the important stuff into the local db
          @mod_db.execute("REPLACE INTO valheim_thunderstore (name, owner, full_name, package_url, date_updated, uuid4, current_version, download_url, dependencies)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)", [entry["name"], entry["owner"], entry["full_name"], entry["package_url"], entry["date_updated"], entry["uuid"], ver, download_url, dependencies])
        end

      else
        LOG.warn("Invalid game (#{game}) passed to modmanager, please add support for the game before building its mod-library.")
      end

    end

    def self.thunderstore_check_for_named_mod(modname, version: 'latest')
      mod_info = ModLibrary.check_for_named_mod(modname, 'valheim_thunderstore')
      selected_version = ""
      if version == "latest"
        selected_version = mod_info[:current_version]
      else
        selected_version = version
      end
      mod_info[:version_download_url] = "#{mod_info[:download_url]}/#{selected_version}/"
      mod_info[:target_version] = selected_version
      return mod_info
    end

    def self.check_for_named_mod(modname, modsource)
      mod_results = @mod_db.execute("SELECT * FROM #{modsource} WHERE full_name LIKE '%#{modname}%'")
      selected_mod = mod_results[0]
      mod_hash = { name: selected_mod[0], owner: selected_mod[1], full_name: selected_mod[2], package_url: selected_mod[3], date_updated: selected_mod[4], uuid4: selected_mod[5], current_version: selected_mod[6], download_url: selected_mod[7], dependencies: selected_mod[8] }
      if mod_results.length > 1
        available_modnames = []
        mod_results.each do |mod_result|
          available_modnames << mod_result[2]
        end
        LOG.warn("Multiple Mods detected when searching for #{modname}. Selected: #{selected_mod[2]}")
        LOG.warn("Mods found when searching '#{modname}' : #{available_modnames}")
      end
      return mod_hash
    end

    # SQLite3::Database.new( "data.db" ) do |db|
    #   db.execute( "select * from table" ) do |row|
    #     p row
    #   end
    # end
    
  end
end
