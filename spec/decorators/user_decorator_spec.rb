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

end
