module SteamHydra
  # Mod manager API for the thunderstore
  module ThunderstoreAPI


    # This is an extremely slow call and as such we want to cache/store the data as much as possible
    def self.get_available_modlist(community)
      modlist = Request.make(
        host: 'https://thunderstore.io',
        path: "/c/#{community}/api/v1/package/",
        method: :get,
        headers: {
          'Content-Type' => 'application/json',
          'accept' => 'application/json'
        }
      )
      return JSON.parse(modlist[:body])
    end

    def self.get_communities()
      communities = Request.make(
        host: 'https://thunderstore.io',
        path: '/api/experimental/community/',
        method: :get,
        headers: {
          'Content-Type' => 'application/json',
          'accept' => 'application/json'
        }
      )
      return JSON.parse(communities[:body])
    end
  end
end
