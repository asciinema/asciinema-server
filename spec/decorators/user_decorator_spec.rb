require 'spec_helper'

describe UserDecorator do

  let(:decorator) { described_class.new(user) }

  describe '#link' do
    subject { decorator.link }

    let(:user) { User.new(nickname: 'satyr') }

    before do
      allow(h).to receive(:profile_path).with(user) { '/path' }
    end

    context "when user is real" do
      before do
        user.dummy = false
      end

      it "is a nickname link to user's profile" do
        expect(subject).to eq('<a href="/path" title="satyr">satyr</a>')
      end
    end

    context "when user is dummy" do
      before do
        user.dummy = true
      end

      it "is user's nickname" do
        expect(subject).to eq('satyr')
      end
    end
  end

  describe '#img_link' do
    subject { decorator.img_link }

    let(:user) { User.new(nickname: 'satyr') }

    before do
      allow(h).to receive(:profile_path).with(user) { '/path' }
      allow(decorator).to receive(:avatar_image_tag) { '<img ...>'.html_safe }
    end

    context "when user is real" do
      before do
        user.dummy = false
      end

      it "is an avatar link to user's profile" do
        expect(subject).to eq('<a href="/path" title="satyr"><img ...></a>')
      end
    end

    context "when user is dummy" do
      before do
        user.dummy = true
      end

      it "is user's avatar image" do
        expect(subject).to eq('<img ...>')
      end
    end
  end

  describe '#full_name' do
    subject { decorator.full_name }

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

  describe '#joined_at' do
    subject { decorator.joined_at }

    let(:user) { double('user', created_at: Time.parse('1970-01-01')) }

    it { should eq('Jan 1, 1970') }
  end

end
