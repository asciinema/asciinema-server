require 'spec_helper'
require 'tempfile'

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

  describe '#stdout' do
    let(:asciicast) { Asciicast.new }
    let(:data_uploader) { double('data_uploader', :decompressed_path => '/foo') }
    let(:timing_uploader) { double('timing_uploader', :decompressed_path => '/bar') }
    let(:stdout) { double('stdout', :lazy => lazy_stdout) }
    let(:lazy_stdout) { double('lazy_stdout') }

    subject { asciicast.stdout }

    before do
      allow(BufferedStdout).to receive(:new) { stdout }
      allow(StdoutDataUploader).to receive(:new) { data_uploader }
      allow(StdoutTimingUploader).to receive(:new) { timing_uploader }
    end

    it 'creates a new BufferedStdout instance' do
      subject

      expect(BufferedStdout).to have_received(:new).with('/foo', '/bar')
    end

    it 'returns lazy instance of stdout' do
      expect(subject).to be(lazy_stdout)
    end
  end

end
