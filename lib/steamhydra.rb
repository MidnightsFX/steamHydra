require 'steamhydra/configuration'
require 'steamhydra/filemanipulator'
require 'steamhydra/GameController'
require 'steamhydra/supervisor'
require 'steamhydra/startupmanager'

module SteamHydra
  # Handle being told to kill the container
  Signal.trap('TERM') { SteamHydra.shutdown_hook }
  # Handle user requested exit
  Signal.trap('SIGINT') { SteamHydra.shutdown_hook }

  def self.shutdown_hook
    puts 'Recieved shutdown, starting shutdown.'
    SteamHydra.config(:server_thread).kill
    puts 'Server exited.'
    exit
  end
end
