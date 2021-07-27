require 'steam-condenser'

module SteamHydra
  module SteamQueries

    # Returns true if there are players on the server, false otherwise
    def self.check_for_active_players()
      case SteamHydra.config[:server]
      when 'Valheim'
        players = SteamQueries.check_valheim_for_players()
        return players.positive? ? true : false
      end
    end

    # This method makes a request for a2s info from a steam server
    # https://developer.valvesoftware.com/wiki/Server_queries#A2S_INFO
    def self.check_valheim_for_players()

      stm_port = SteamHydra.config[:port] + 1 # Valheim steam status port is game port + 1
      server = SourceServer.new('0.0.0.0', stm_port)
      server.init
      #  Get the current players from the server
      server.update_server_info
      info = server.server_info
      LOG.debug("Found the following server information: #{info}")
      return info[:number_of_players]
    end

  end
end
