require 'rails_helper'

describe "asciicasts routing" do

  it 'routes /a/1 to asciicasts#show' do
    expect(get: '/a/1').to route_to(
      controller: 'asciicasts',
      action:     'show',
      id:         '1',
    )
  end

  it 'routes /a/1.js to api/asciicasts#show' do
    expect(get: '/a/1.js').to route_to(
      controller: 'api/asciicasts',
      action:     'show',
      id:         '1',
      format:     'js',
    )
  end

  # legacy route, kept for backwards compatibility with old embeds
  it 'routes /a/1/raw to api/asciicasts#show' do
    expect(get: '/a/1/raw').to route_to(
      controller: 'api/asciicasts',
      action:     'show',
      id:         '1',
    )
  end

end
