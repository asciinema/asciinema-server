require 'rails_helper'

describe UserDecorator do

  let(:decorator) { described_class.new(user) }

  describe '#link' do
    subject { decorator.link }

    let(:user) { User.new }

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
      before do
        user.username = "satyr"
      end

      it "is a username link to user's profile" do
        expect(subject).to eq('<a href="/path" title="satyr">satyr</a>')
      end
    end

    context "when user has temporary username" do
      before do
        user.temporary_username = "temp"
      end

      it "is user's username" do
        expect(subject).to eq('temp')
      end
    end

    context "when user has neither username nor temporary username" do
      before do
        user.username = user.temporary_username = nil
      end

      it 'is "anonymous"' do
        expect(subject).to eq('anonymous')
      end
    end
  end

  describe '#img_link' do
    subject { decorator.img_link }

    let(:user) { User.new }

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

    context "when user has username" do
      before do
        user.username = "satyr"
      end

      it "is an avatar link to user's profile" do
        expect(subject).to eq('<a href="/path" title="satyr"><img ...></a>')
      end
    end

    context "when user has no username" do
      before do
        user.username = nil
      end

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
