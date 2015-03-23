require 'rails_helper'

describe "Asciicast creation" do

  let(:created_asciicast) { Asciicast.last }

  def basic_auth_header(user, password)
    { 'HTTP_AUTHORIZATION' => ActionController::HttpAuthentication::Basic.encode_credentials(user, password) }
  end

  def user_agent_header(user_agent)
    { 'User-Agent' => user_agent }
  end

  def headers(user, password, user_agent)
    {}.tap do |h|
      h.merge!(basic_auth_header(user, password)) if user
      h.merge!(user_agent_header(user_agent)) if user_agent
    end
  end

  context '<= v0.9.7 client' do
    subject { make_request }

    def make_request
      post '/api/asciicasts',
        {
          asciicast: {
            meta:          fixture_file('0.9.7/meta.json',   'application/json'),
            stdout:        fixture_file('0.9.7/stdout',      'application/octet-stream'),
            stdout_timing: fixture_file('0.9.7/stdout.time', 'application/octet-stream')
        }
      }, headers(nil, nil, 'python-requests blah/blah')
    end

    before { subject }

    it 'creates asciicast version 0' do
      expect(created_asciicast.version).to eq(0)
    end

    it 'creates asciicast with given stdout data file' do
      expect(created_asciicast.stdout_data).to_not be(nil)
    end

    it 'creates asciicast with given stdout timing file' do
      expect(created_asciicast.stdout_timing).to_not be(nil)
    end

    it 'creates asciicast with given command' do
      expect(created_asciicast.command).to eq('/bin/bash')
    end

    it 'creates asciicast with given duration' do
      expect(created_asciicast.duration).to eq(11.146430015564)
    end

    it 'creates asciicast with given shell' do
      expect(created_asciicast.shell).to eq('/bin/zsh')
    end

    it 'creates asciicast with given terminal type' do
      expect(created_asciicast.terminal_type).to eq('screen-256color')
    end

    it 'creates asciicast with given terminal width' do
      expect(created_asciicast.terminal_columns).to eq(96)
    end

    it 'creates asciicast with given terminal height' do
      expect(created_asciicast.terminal_lines).to eq(26)
    end

    it 'creates asciicast with given title' do
      expect(created_asciicast.title).to eq('bashing :)')
    end

    it 'creates asciicast with given uname' do
      expect(created_asciicast.uname).to eq('Linux 3.9.9-302.fc19.x86_64 #1 SMP Sat Jul 6 13:41:07 UTC 2013 x86_64')
    end

    it 'creates asciicast with no user agent set' do
      expect(created_asciicast.user_agent).to be(nil)
    end

    context 'when a user with given token does not exist' do
      let(:created_user) { User.last }

      it 'creates new user with given username and token' do
        expect(created_user.temporary_username).to eq('kill')
        expect(created_user.api_tokens.first.token).to eq('f33e6188-f53c-11e2-abf4-84a6c827e88b')
      end

      it 'creates asciicast assigned to newly created user' do
        expect(created_asciicast.user).to eq(created_user)
      end
    end

    context 'when a user with given token exists' do
      let(:user) { User.create_with_token('f33e6188-f53c-11e2-abf4-84a6c827e88b', 'kill') }

      subject do
        user
        make_request
      end

      it 'creates asciicast assigned to a user with given token' do
        expect(created_asciicast.user).to eq(user)
      end
    end

    it 'returns the URL to the uploaded asciicast' do
      expect(response.body).to eq(asciicast_url(created_asciicast))
    end
  end

  context 'v0.9.8 client' do
    subject { make_request }

    def make_request
      post '/api/asciicasts',
        {
          asciicast: {
            meta:          fixture_file('0.9.8/meta.json',   'application/json'),
            stdout:        fixture_file('0.9.8/stdout',      'application/octet-stream'),
            stdout_timing: fixture_file('0.9.8/stdout.time', 'application/octet-stream')
          }
        }, headers(nil, nil, 'asciinema/0.9.8 CPython/2.7.4 Jola/Misio-Foo')
    end

    before { subject }

    it 'creates asciicast version 0' do
      expect(created_asciicast.version).to eq(0)
    end

    it 'creates asciicast with given stdout data file' do
      expect(created_asciicast.stdout_data).to_not be(nil)
    end

    it 'creates asciicast with given stdout timing file' do
      expect(created_asciicast.stdout_timing).to_not be(nil)
    end

    it 'creates asciicast with given command' do
      expect(created_asciicast.command).to eq('/bin/bash')
    end

    it 'creates asciicast with given duration' do
      expect(created_asciicast.duration).to eq(11.146430015564)
    end

    it 'creates asciicast with given shell' do
      expect(created_asciicast.shell).to eq('/bin/zsh')
    end

    it 'creates asciicast with given terminal type' do
      expect(created_asciicast.terminal_type).to eq('screen-256color')
    end

    it 'creates asciicast with given terminal width' do
      expect(created_asciicast.terminal_columns).to eq(96)
    end

    it 'creates asciicast with given terminal height' do
      expect(created_asciicast.terminal_lines).to eq(26)
    end

    it 'creates asciicast with given title' do
      expect(created_asciicast.title).to eq('bashing :)')
    end

    it 'creates asciicast with nil uname' do
      expect(created_asciicast.uname).to be(nil)
    end

    it 'creates asciicast with given user agent' do
      expect(created_asciicast.user_agent).to eq('asciinema/0.9.8 CPython/2.7.4 Jola/Misio-Foo')
    end

    context 'when a user with given token does not exist' do
      let(:created_user) { User.last }

      it 'creates new user with given username and token' do
        expect(created_user.temporary_username).to eq('kill')
        expect(created_user.api_tokens.first.token).to eq('f33e6188-f53c-11e2-abf4-84a6c827e88b')
      end

      it 'creates asciicast assigned to newly created user' do
        expect(created_asciicast.user).to eq(created_user)
      end
    end

    context 'when a user with given token exists' do
      let(:user) { User.create_with_token('f33e6188-f53c-11e2-abf4-84a6c827e88b', 'kill') }

      subject do
        user
        make_request
      end

      it 'creates asciicast assigned to a user with given token' do
        expect(created_asciicast.user).to eq(user)
      end
    end

    it 'returns the URL to the uploaded asciicast' do
      expect(response.body).to eq(asciicast_url(created_asciicast))
    end
  end

  context 'v0.9.9 client' do
    subject { make_request }

    def make_request
      post '/api/asciicasts',
        {
          asciicast: {
            meta:          fixture_file('0.9.9/meta.json',   'application/json'),
            stdout:        fixture_file('0.9.9/stdout',      'application/octet-stream'),
            stdout_timing: fixture_file('0.9.9/stdout.time', 'application/octet-stream')
          }
      }, headers('kill', 'f33e6188-f53c-11e2-abf4-84a6c827e88b', 'asciinema/0.9.9 gc/go1.3 jola-amd64')
    end

    before { subject }

    it 'creates asciicast version 0' do
      expect(created_asciicast.version).to eq(0)
    end

    it 'creates asciicast with given stdout data file' do
      expect(created_asciicast.stdout_data).to_not be(nil)
    end

    it 'creates asciicast with given stdout timing file' do
      expect(created_asciicast.stdout_timing).to_not be(nil)
    end

    it 'creates asciicast with given command' do
      expect(created_asciicast.command).to eq('/bin/bash')
    end

    it 'creates asciicast with given duration' do
      expect(created_asciicast.duration).to eq(11.146430015564)
    end

    it 'creates asciicast with given shell' do
      expect(created_asciicast.shell).to eq('/bin/zsh')
    end

    it 'creates asciicast with given terminal type' do
      expect(created_asciicast.terminal_type).to eq('screen-256color')
    end

    it 'creates asciicast with given terminal width' do
      expect(created_asciicast.terminal_columns).to eq(96)
    end

    it 'creates asciicast with given terminal height' do
      expect(created_asciicast.terminal_lines).to eq(26)
    end

    it 'creates asciicast with given title' do
      expect(created_asciicast.title).to eq('bashing :)')
    end

    it 'creates asciicast with nil uname' do
      expect(created_asciicast.uname).to be(nil)
    end

    it 'creates asciicast with given user agent' do
      expect(created_asciicast.user_agent).to eq('asciinema/0.9.9 gc/go1.3 jola-amd64')
    end

    context 'when a user with given token does not exist' do
      let(:created_user) { User.last }

      it 'creates new user with given username and token' do
        expect(created_user.temporary_username).to eq('kill')
        expect(created_user.api_tokens.first.token).to eq('f33e6188-f53c-11e2-abf4-84a6c827e88b')
      end

      it 'creates asciicast assigned to newly created user' do
        expect(created_asciicast.user).to eq(created_user)
      end
    end

    context 'when a user with given token exists' do
      let(:user) { User.create_with_token('f33e6188-f53c-11e2-abf4-84a6c827e88b', 'kill') }

      subject do
        user
        make_request
      end

      it 'creates asciicast assigned to a user with given token' do
        expect(created_asciicast.user).to eq(user)
      end
    end

    it 'returns the URL to the uploaded asciicast' do
      expect(response.body).to eq(asciicast_url(created_asciicast))
    end
  end

  context 'format 1' do
    subject { make_request }

    def make_request
      post '/api/asciicasts',
        { asciicast: fixture_file('1/asciicast.json', 'application/json') },
        headers('kill', 'f33e6188-f53c-11e2-abf4-84a6c827e88b', 'asciinema/1.0.0 gc/go1.3 jola-amd64')
    end

    before { subject }

    it 'creates asciicast version 1' do
      expect(created_asciicast.version).to eq(1)
    end

    it 'creates asciicast with given file' do
      expect(created_asciicast.file).to_not be(nil)
    end

    it 'creates asciicast with given command' do
      expect(created_asciicast.command).to eq('/bin/bash')
    end

    it 'creates asciicast with given duration' do
      expect(created_asciicast.duration).to eq(11.146430015564)
    end

    it 'creates asciicast with given shell' do
      expect(created_asciicast.shell).to eq('/bin/zsh')
    end

    it 'creates asciicast with given terminal type' do
      expect(created_asciicast.terminal_type).to eq('screen-256color')
    end

    it 'creates asciicast with given terminal width' do
      expect(created_asciicast.terminal_columns).to eq(96)
    end

    it 'creates asciicast with given terminal height' do
      expect(created_asciicast.terminal_lines).to eq(26)
    end

    it 'creates asciicast with given title' do
      expect(created_asciicast.title).to eq('bashing :)')
    end

    it 'creates asciicast with nil uname' do
      expect(created_asciicast.uname).to be(nil)
    end

    it 'creates asciicast with given user agent' do
      expect(created_asciicast.user_agent).to eq('asciinema/1.0.0 gc/go1.3 jola-amd64')
    end

    context 'when a user with given token does not exist' do
      let(:created_user) { User.last }

      it 'creates new user with given username and token' do
        expect(created_user.temporary_username).to eq('kill')
        expect(created_user.api_tokens.first.token).to eq('f33e6188-f53c-11e2-abf4-84a6c827e88b')
      end

      it 'creates asciicast assigned to newly created user' do
        expect(created_asciicast.user).to eq(created_user)
      end
    end

    context 'when a user with given token exists' do
      let(:user) { User.create_with_token('f33e6188-f53c-11e2-abf4-84a6c827e88b', 'kill') }

      subject do
        user
        make_request
      end

      it 'creates asciicast assigned to a user with given token' do
        expect(created_asciicast.user).to eq(user)
      end
    end

    it 'returns the URL to the uploaded asciicast' do
      expect(response.body).to eq(asciicast_url(created_asciicast))
    end
  end

end
