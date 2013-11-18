require 'spec_helper'

describe UserDecorator do

  let(:decorator) { described_class.new(user) }
  let(:user) { double('user', avatar_url: avatar_url, email: 'foo@email.com') }

  describe '#avatar_url' do
    subject { decorator.avatar_url }

    context "when avatar_url present on user" do
      let(:avatar_url) { 'http://avatar/url' }

      it { should eq('http://avatar/url') }
    end

    context "when avatar_url missing on user" do
      let(:avatar_url) { nil }

      it {
        should
          eq('//gravatar.com/avatar/9dcfeb70fe212ea12562dddd22b0fc92?s=128')
      }
    end
  end

end
