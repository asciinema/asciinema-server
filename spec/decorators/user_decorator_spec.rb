require 'rails_helper'

describe UserDecorator do

  let(:decorator) { described_class.new(user) }

  describe '#link' do
    subject { decorator.link }

    before do
      RSpec::Mocks.configuration.verify_partial_doubles = false # for stubbing "h"
    end

    before do
      allow(h).to receive(:profile_path).with(user) { '/path' }
    end

    after do
      RSpec::Mocks.configuration.verify_partial_doubles = true
    end

    context "when user has username" do
      let(:user) { create(:user, username: "satyr") }

      it "is a username link to user's profile" do
        expect(subject).to eq('<a href="/path" title="satyr">satyr</a>')
      end
    end

    context "when user has temporary username" do
      let(:user) { create(:unconfirmed_user, temporary_username: "frost") }

      it "is a temporary username link to user's profile" do
        expect(subject).to eq('<a href="/path" title="frost">frost</a>')
      end
    end

    context "when user has not username nor temporary username" do
      let(:user) { create(:unconfirmed_user, temporary_username: nil) }

      it "is id-based link to user's profile" do
        expect(subject).to eq(%(<a href="/path" title="user:#{user.id}">user:#{user.id}</a>))
      end
    end
  end

  describe '#img_link' do
    subject { decorator.img_link }

    before do
      RSpec::Mocks.configuration.verify_partial_doubles = false # for stubbing "h"
    end

    before do
      allow(h).to receive(:profile_path).with(user) { '/path' }
      allow(decorator).to receive(:avatar_image_tag) { '<img ...>'.html_safe }
    end

    after do
      RSpec::Mocks.configuration.verify_partial_doubles = true
    end

    context "when user is persisted and has username" do
      let(:user) { create(:user, username: "satyr") }

      it "is an avatar link to user's profile" do
        expect(subject).to eq('<a href="/path" title="satyr"><img ...></a>')
      end
    end

    context "when user is persisted and has temporary username" do
      let(:user) { create(:unconfirmed_user, temporary_username: "frost") }

      it "is an avatar link to user's profile" do
        expect(subject).to eq('<a href="/path" title="frost"><img ...></a>')
      end
    end

    context "when user is not persisted" do
      let(:user) { User.new }

      it "is user's avatar image" do
        expect(subject).to eq('<img ...>')
      end
    end
  end

  describe '#full_name' do
    subject { decorator.full_name }

    let(:user) { double('user', username: 'sickill', name: name) }

    context "when full name is present" do
      let(:name) { 'Marcin Kulik' }

      it { should eq('Marcin Kulik (sickill)') }
    end

    context "when fill name is missing" do
      let(:name) { nil }

      it { should eq('sickill') }
    end
  end

  describe '#joined_at' do
    subject { decorator.joined_at }

    let(:user) { double('user', created_at: Time.parse('1970-01-01')) }

    it { should eq('Jan 1, 1970') }
  end

end
