require 'steamhydra/configuration'
require 'steamhydra/filemanipulator'
require 'steamhydra/GameController'
require 'steamhydra/supervisor'
require 'steamhydra/startupmanager'
require 'steamhydra/steamqueries'

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
    SteamHydra.config(:server_thread).kill
    puts 'Server exited.'
    exit
  end
end
