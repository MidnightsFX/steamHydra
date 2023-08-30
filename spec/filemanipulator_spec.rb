RSpec.describe SteamHydra::FileManipulator do
  describe 'Gem file locator' do
    it 'returns the location of the gem' do
      location = SteamHydra::FileManipulator.gem_resource_location
      folders = location.split('/')
      expect(folders[-1]).to eq("lib")
      expect(folders[-2]).to eq("steamhydra")
    end
  end

  describe 'Modtools installer' do
    it "installs modtools for valheim based on the latest available", :this do
      SteamHydra.set_debug
      SteamHydra.check_and_set_server("Valheim")
      SteamHydra.set_cfg_value(:modded, true)
      SteamHydra.set_cfg_value(:modded_metadata, { bepinex: 'latest' })
      SteamHydra::FileManipulator.install_modtools(target_directory: "#{__dir__}/test_data/")
    end
  end
end
