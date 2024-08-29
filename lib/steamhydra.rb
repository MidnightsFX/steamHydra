require 'steamhydra/configuration'
require 'steamhydra/utilities/request'
require 'steamhydra/utilities/logrotate'
require 'steamhydra/filemanipulator'
require 'steamhydra/GameController'
require 'steamhydra/supervisor'
require 'steamhydra/startupmanager'
require 'steamhydra/server_status_manager/steamqueries'
require 'steamhydra/mod_managers/thunderstoreapi'
require 'steamhydra/mod_managers/modlibrary'
require 'steamhydra/mod_managers/modmanager'

require 'date'
require 'json'

module SteamHydra

  def self.shutdown_hook(signal = nil)
    puts "Recieved signal: #{signal}, starting shutdown."
    pid = `cat /server/server_pid`
    `kill -s SIGINT #{pid}`
    sleep 120
    puts 'Server exited.'
    exit
  end
end

  # Handle being told to kill the container
  Signal.trap(0, proc { puts "Terminating: #{$$}" })

  Signal.trap('INT') { SteamHydra.shutdown_hook("INT") }
  Signal.trap('TRAP') { SteamHydra.shutdown_hook("TRAP") }
  Signal.trap('TERM') { SteamHydra.shutdown_hook("TERM") }
