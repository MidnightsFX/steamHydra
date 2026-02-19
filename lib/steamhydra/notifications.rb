module SteamHydra
  module Notifications
    def self.SendMessage(message)
      return if SteamHydra.config.key?(:message_system) == false

      if (SteamHydra.config[:message_system] == :discord)
        SendMessageTodiscord(message)
      end
    end

    def self.SendMessageTodiscord(message)
      return if SteamHydra.config.key?(:discord) == false

      durl = URI.parse(SteamHydra.config[:discord])
      discord_resp = Request.make(
        host: "https://#{durl.host}",
        path: "#{durl.path}",
        headers: { "Content-Type" => "application/json" },
        method: :post,
        body: JSON.generate({"content": message})
      )
      return discord_resp
    end
  end
end