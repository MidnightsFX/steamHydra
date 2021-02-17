require 'net/http'

module SteamHydra
  module SteamQueries

    # This metho makes a request for a2s info from a steam server
    # https://developer.valvesoftware.com/wiki/Server_queries#A2S_INFO
    def self.request_server_a2s_info()
      case SteamHydra.config[:server]
      when 'Valheim'
        stm_port = SteamHydra.config[:port] + 1 # Valheim steam status port is game port + 1
        LOG.debug("URI: 0.0.0.0:#{stm_port}")
      end
      #server = GameServer.new('0.0.0.0', stm_port)
      #server.init
      # Get the current players from the server
      #players = server.players
      #LOG.debug("Found the following players: #{players}")
    end

  end
end
