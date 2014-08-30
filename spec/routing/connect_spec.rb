require 'rails_helper'

describe 'connect routing' do
  it 'routes /connect/:api_token to api_tokens#create for api_token' do
    expect({ :get => '/connect/jolka-misio' }).to route_to(
      :controller => 'api_tokens',
      :action     => 'create',
      :api_token => 'jolka-misio'
    )
  end
end
