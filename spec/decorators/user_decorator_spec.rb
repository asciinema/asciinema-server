require 'spec_helper'

describe UserDecorator do

  let(:decorator) { described_class.new(user) }

  describe '#avatar_url' do
    subject { decorator.avatar_url }

    let(:user) { double('user', avatar_url: avatar_url, email: email) }

    context "when use has avatar_url" do
      let(:avatar_url) { 'http://avatar/url' }

      context "and user has email" do
        let(:email) { 'foo@email.com' }

        it {
          should
             eq('//gravatar.com/avatar/9dcfeb70fe212ea12562dddd22b0fc92?s=128')
        }
      end

      context "and user has no email" do
        let(:email) { nil }

        it { should eq('http://avatar/url') }
      end
    end

    context "when user has neither email nor avatar_url" do
      let(:email) { nil }
      let(:avatar_url) { nil }

      it { should eq(h.default_avatar_filename) }
    end
  end

  describe '#fullname_and_nickname' do
    subject { decorator.fullname_and_nickname }

    let(:user) { double('user', nickname: 'sickill', name: name) }

    context "when full name is present" do
      let(:name) { 'Marcin Kulik' }

      it { should eq('Marcin Kulik (sickill)') }
    end

    context "when fill name is missing" do
      let(:name) { nil }

      it { should eq('sickill') }
    end
  end

end
