require 'rails_helper'

describe "asciicasts routing" do

  it 'routes /a/1 to asciicasts#show' do
    expect(get: '/a/1').to route_to(
      controller: 'asciicasts',
      action:     'show',
      id:         '1',
    )
  end

  # legacy route, kept for backwards compatibility with old embeds
  it 'routes /a/1/raw to asciicasts#embed' do
    expect(get: '/a/1/raw').to route_to(
      controller: 'asciicasts',
      action:     'embed',
      id:         '1',
    )
  end

end
