require 'rails_helper'

describe AsciicastPagePresenter do

  let(:routes) {
    controller = ApplicationController.new
    controller.request = ActionController::TestRequest.new
    controller.view_context
  }

  describe '.build' do
    subject { described_class.build(routes, asciicast, user, playback_options) }

    let(:asciicast) { stub_model(Asciicast, decorate: decorated_asciicast) }
    let(:user) { double('user') }
    let(:playback_options) { { speed: 3.0 } }
    let(:decorated_asciicast) { double('decorated_asciicast', theme_name: 'foo') }

    it "builds presenter with given asciicast decorated" do
      expect(subject.asciicast).to be(decorated_asciicast)
    end

    it "builds presenter with given user" do
      expect(subject.current_user).to be(user)
    end

    it "builds presenter with given playback options" do
      expect(subject.playback_options.speed).to eq(3.0)
      expect(subject.playback_options.theme).to eq('foo')
    end
  end

  let(:presenter) { described_class.new(routes, asciicast, current_user, policy, nil) }
  let(:asciicast) { stub_model(Asciicast, user: author).decorate }
  let(:current_user) { User.new }
  let(:policy) { double('policy') }
  let(:author) { User.new }

  describe '#title' do
    subject { presenter.title }

    before do
      allow(asciicast).to receive(:title) { 'the-title' }
    end

    it { should eq('the-title') }
  end

  describe '#asciicast_title' do
    subject { presenter.asciicast_title }

    before do
      allow(asciicast).to receive(:title) { 'the-title' }
    end

    it { should eq('the-title') }
  end

  describe '#author_img_link' do
    subject { presenter.author_img_link }

    before do
      allow(asciicast).to receive(:author_img_link) { '<a href=...>' }
    end

    it { should eq('<a href=...>') }
  end

  describe '#author_link' do
    subject { presenter.author_link }

    before do
      allow(asciicast).to receive(:author_link) { '<a href=...>' }
    end

    it { should eq('<a href=...>') }
  end

  describe '#asciicast_created_at' do
    subject { presenter.asciicast_created_at }

    let(:now) { Time.now }

    before do
      allow(asciicast).to receive(:created_at) { now }
    end

    it { should eq(now) }
  end

  describe '#asciicast_env_details' do
    subject { presenter.asciicast_env_details }

    before do
      allow(asciicast).to receive(:os) { 'Linux' }
      allow(asciicast).to receive(:shell) { 'bash' }
      allow(asciicast).to receive(:terminal_type) { 'xterm' }
    end

    it { should eq('Linux / bash / xterm') }
  end

  describe '#views_count' do
    subject { presenter.views_count }

    before do
      allow(asciicast).to receive(:views_count) { 5 }
    end

    it { should eq(5) }
  end

  describe '#show_description?' do
    subject { presenter.show_description? }

    before do
      allow(asciicast).to receive(:description) { description }
    end

    context "when description is present" do
      let(:description) { 'i am description' }

      it { should be(true) }
    end

    context "when description isn't present" do
      let(:description) { '' }

      it { should be(false) }
    end
  end

  describe '#description' do
    subject { presenter.description }

    before do
      allow(asciicast).to receive(:description) { 'i am description' }
    end

    it { should eq('i am description') }
  end

  describe '#other_asciicasts_by_author' do
    subject { presenter.other_asciicasts_by_author }

    let(:others) { double('others', decorate: decorated_others) }
    let(:decorated_others) { double('decorated_others') }

    before do
      allow(author).to receive(:other_asciicasts).
        with(asciicast, 3) { others }
    end

    it "returns decorated asciicasts excluding the given one" do
      expect(subject).to be(decorated_others)
    end
  end

end
