require 'spec_helper'

describe 'routing to API v0' do
  it 'routes POST /api/asciicasts to api/v0/asciicasts#create for api_token' do
    expect(post: '/api/asciicasts').to route_to(
      controller: 'api/v0/asciicasts',
      action:     'create',
    )
  end
end
