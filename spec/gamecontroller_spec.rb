RSpec.describe SteamHydra::GameController do
  describe 'Gamecontroller functions' do
    it "Should connect to the steam web api to get metadata about the installed games current version", :steamapi do
      SteamHydra.set_debug
      SteamHydra.check_and_set_server("Valheim")
      SteamHydra::GameController.get_game_metadata()
    end
  end
end
