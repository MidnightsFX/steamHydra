RSpec.describe SteamHydra do
  it 'has a version number' do
    expect(SteamHydra::VERSION).not_to be nil
  end

  # it 'Can connect to a steam server for an a2s query' do
  #   SteamHydra::SteamQueries.request_for_valve_server(request: "'Source Engine Query\0'", address: '50.39.102.167', port: 2456)
  # end
end
