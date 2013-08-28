require 'spec_helper'

describe Asciicast do

  let(:asciicast) { Asciicast.new }

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

  # TODO: create a service for this
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

  describe '#update_snapshot' do
    let(:asciicast) { create(:asciicast) }
    let(:snapshot) { [[[{ :foo => 'bar' }]]] }

    it 'persists the snapshot' do
      asciicast.update_snapshot(snapshot)
      snapshot = Asciicast.find(asciicast.id).snapshot

      expect(snapshot).to eq([[[{ 'foo' => 'bar' }]]])
    end
  end

  describe '#stdout' do
    let(:asciicast) { stub_model(Asciicast) }
    let(:data_file) { double('data_file', :decompressed_path => '/foo') }
    let(:timing_file) { double('timing_file', :decompressed_path => '/bar') }
    let(:stdout) { double('stdout') }

    before do
      allow(asciicast).to receive(:stdout_data) { data_file }
      allow(asciicast).to receive(:stdout_timing) { timing_file }
      allow(BufferedStdout).to receive(:new) { stdout }
    end

    it 'creates a new BufferedStdout instance' do
      asciicast.stdout

      expect(BufferedStdout).to have_received(:new).with('/foo', '/bar')
    end

    it 'returns created Stdout instance' do
      expect(asciicast.stdout).to be(stdout)
    end
  end
end
