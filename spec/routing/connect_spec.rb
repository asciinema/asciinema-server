require 'spec_helper'

describe 'connect routing' do
  it 'routes /connect/:user_token to user_tokens#create for user_token' do
    expect({ :get => '/connect/jolka-misio' }).to route_to(
      :controller => 'user_tokens',
      :action     => 'create',
      :user_token => 'jolka-misio'
    )
  end
end
