require 'steamhydra/configuration'
require 'steamhydra/filemanipulator'
require 'steamhydra/gamecontroller'
require 'steamhydra/supervisor'
require 'steamhydra/startupmanager'
require 'steamhydra/server_status_manager/steamqueries'

module SteamHydra
  # Handle being told to kill the container
  Signal.trap(0, proc { puts "Terminating: #{$$}" })
  # 30.times do |signal|
  #   puts "Setting up singal handler: #{signal}"
  #   Signal.trap(signal) { SteamHydra.shutdown_hook(signal) }
  # end

  Signal.trap('INT') { SteamHydra.shutdown_hook }
  Signal.trap('TRAP') { SteamHydra.shutdown_hook }

  def self.shutdown_hook(signal = nil)
    puts "Recieved signal: #{signal}, starting shutdown."
    GameController.stop_server_thread
    puts 'Server exited.'
    exit
  end
end
