RSpec.describe SteamHydra::FileManipulator do
  describe 'Gem file locator' do
    it 'returns the location of the gem' do
      location = SteamHydra::FileManipulator.gem_resource_location
      folders = location.split('/')
      expect(folders[-1]).to eq("lib")
      expect(folders[-2]).to eq("steamhydra")
    end
  end
end
