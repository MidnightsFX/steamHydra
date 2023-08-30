RSpec.describe SteamHydra do
  describe 'thunderstore_manager' do
    WebMock.allow_net_connect!

    it 'can request packages for a community' do
      SteamHydra.set_debug
      modlist = SteamHydra::ThunderstoreAPI.get_available_modlist('valheim')
      # File.open("test.json", "w") do |file|
      #   modlist.each do |mod_entry|
      #     file.write("#{mod_entry}\n")
      #   end
      # end

    end

    it 'Builds the local mod database', :moddb do
      #File.write("test.json", modlist)
      # puts JSON.pretty_generate(modlist)
      SteamHydra::ModLibrary.create_modtables_if_missing
    end

    it 'queries the local mod_db' do
      mod_result = SteamHydra::ModLibrary.thunderstore_check_for_named_mod("ValheimArmory")
      puts "Mod: #{mod_result}"
    end

    it 'checks the local modprofile cache' do 
      puts SteamHydra::ModManager.check_mod_profile
    end

    it 'downloads and installs modfiles that are managed, removes unmanaged ones', :modtest do
      SteamHydra.set_debug
      ENV['Mods'] = "CreatureLevelAndLootControl,ValheimArmory"
      SteamHydra.check_and_set_server("Valheim")
      SteamHydra::ModManager.install_or_update_mods(server_directory: "#{__dir__}/test_data/")
    end

    it 'should check the modprofile and moddb for updates', :modupdate do
      puts SteamHydra::ModManager.updates_available_from_mod_profile
    end
  end
end
