require 'spec_helper'

describe Asciicast do
  describe '.assign_user' do
    let(:user) { FactoryGirl.create(:user) }
    let(:token) { 'token' }
    let!(:asciicast) do
      FactoryGirl.create(:asciicast, :user => nil, :user_token => token)
    end

    subject { Asciicast.assign_user(token, user) }

    it 'returns number of updated records' do
      subject.should == 1
    end

    it 'assigns user to matching asciicasts' do
      subject
      asciicast.reload.user.should == user
    end
  end

  describe '#save' do
    let(:asciicast) { FactoryGirl.build(:asciicast, :user => user) }

    context 'when no user given' do
      let(:user) { nil }

      it 'calls #assign_user' do
        asciicast.should_receive(:assign_user)
        asciicast.save
      end
    end

    context 'when user given' do
      let(:user) { FactoryGirl.build(:user) }

      it "doesn't call #assign_user" do
        asciicast.should_not_receive(:assign_user)
        asciicast.save
      end
    end
  end

  describe '#assign_user' do
    let(:user) { FactoryGirl.create(:user) }
    let(:asciicast) do
      FactoryGirl.create(:asciicast, :user => nil, :user_token => user_token)
    end

    context 'when user exists with given token' do
      let(:user_token) { FactoryGirl.create(:user_token, :user => user).token }

      it 'assigns user and resets user_token' do
        asciicast.assign_user
        asciicast.user.should == user
        asciicast.user_token.should be(nil)
      end
    end

    context 'when there is no user with given token' do
      let(:user_token) { 'some-foo-bar' }

      it 'assigns user' do
        asciicast.assign_user
        asciicast.user.should be(nil)
      end
    end
  end

  describe '#meta=' do
    let(:asciicast) { stub_model(Asciicast) }

    let(:username) { 'username' }
    let(:user_token) { 'token' }
    let(:duration) { 123.456 }
    let(:recorded_at) { Time.now.to_s }
    let(:title) { 'title' }
    let(:command) { '/bin/command' }
    let(:shell) { '/bin/shell' }
    let(:uname) { 'OS' }
    let(:terminal_lines) { 29 }
    let(:terminal_columns) { 97 }
    let(:terminal_type) { 'xterm-lolz' }

    it 'assigns attributes properly' do
      data = {
        :username => username,
        :user_token => user_token,
        :duration => duration,
        :recorded_at => recorded_at,
        :title => title,
        :command => command,
        :shell => shell,
        :uname => uname,
        :term => {
          :lines => terminal_lines,
          :columns => terminal_columns,
          :type => terminal_type,
        }
      }
      json = data.to_json
      tempfile = stub('tempfile', :read => json)
      json_file = stub('file', :tempfile => tempfile)
      asciicast.meta = json_file

      asciicast.username.should         == username
      asciicast.user_token.should       == user_token
      asciicast.duration.should         == duration
      asciicast.recorded_at.should      == recorded_at
      asciicast.title.should            == title
      asciicast.command.should          == command
      asciicast.shell.should            == shell
      asciicast.uname.should            == uname
      asciicast.terminal_lines.should   == terminal_lines
      asciicast.terminal_columns.should == terminal_columns
      asciicast.terminal_type.should    == terminal_type
    end
  end

  describe '#snapshot' do
    let(:asciicast) { Asciicast.new }
    let(:snapshot) {
      Snapshot.new([
        SnapshotLine.new([
          SnapshotFragment.new('foo', { :fg => 1 })
        ])
      ])
    }

    it 'is empty Snapshot instance initially' do
      expect(asciicast.snapshot).to eq(Snapshot.new)
    end

    it 'is a Snapshot instance before persisting' do
      asciicast.snapshot = snapshot

      expect(asciicast.snapshot).to eq(snapshot)
    end

    it 'is a Snapshot instance after persisting and loading' do
      asciicast = build(:asciicast)
      asciicast.snapshot = snapshot
      asciicast.save!

      expect(asciicast.snapshot).to eq(snapshot)
      expect(Asciicast.find(asciicast.id).snapshot).to eq(snapshot)
    end
  end
end
