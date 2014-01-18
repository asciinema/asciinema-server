require 'spec_helper'

describe AsciicastPresenter do

  let(:presenter) { described_class.new(asciicast, current_user) }
  let(:asciicast) { stub_model(Asciicast, decorate: decorated_asciicast) }
  let(:current_user) { User.new }
  let(:decorated_asciicast) { stub_model(Asciicast, user: author) }
  let(:author) { User.new }

  let(:view_context) {
    controller = ApplicationController.new
    controller.request = ActionController::TestRequest.new
    controller.view_context
  }

  before do
    allow(asciicast).to receive(:decorate) { decorated_asciicast }
  end

  describe '#title' do
    subject { presenter.title }

    before do
      allow(decorated_asciicast).to receive(:title) { 'the-title' }
    end

    it { should eq('the-title') }
  end

  describe '#asciicast_title' do
    subject { presenter.asciicast_title }

    before do
      allow(decorated_asciicast).to receive(:title) { 'the-title' }
    end

    it { should eq('the-title') }
  end

  describe '#author_img_link' do
    subject { presenter.author_img_link }

    before do
      allow(decorated_asciicast).to receive(:author_img_link) { '<a href=...>' }
    end

    it { should eq('<a href=...>') }
  end

  describe '#author_link' do
    subject { presenter.author_link }

    before do
      allow(decorated_asciicast).to receive(:author_link) { '<a href=...>' }
    end

    it { should eq('<a href=...>') }
  end

  describe '#asciicast_created_at' do
    subject { presenter.asciicast_created_at }

    let(:now) { Time.now }

    before do
      allow(decorated_asciicast).to receive(:created_at) { now }
    end

    it { should eq(now) }
  end

  describe '#asciicast_env_details' do
    subject { presenter.asciicast_env_details }

    before do
      allow(decorated_asciicast).to receive(:os) { 'Linux' }
      allow(decorated_asciicast).to receive(:shell) { 'bash' }
      allow(decorated_asciicast).to receive(:terminal_type) { 'xterm' }
    end

    it { should eq('Linux / bash / xterm') }
  end

  describe '#views_count' do
    subject { presenter.views_count }

    before do
      allow(decorated_asciicast).to receive(:views_count) { 5 }
    end

    it { should eq(5) }
  end

  describe '#embed_script' do
    subject { presenter.embed_script(view_context) }

    let(:src_regexp) { /src="[^"]+\b123\b[^"]*\.js"/ }
    let(:id_regexp) { /id="asciicast-123"/ }
    let(:script_regexp) {
      /^<script[^>]+#{src_regexp}[^>]+#{id_regexp}[^>]*><\/script>/
    }

    before do
      allow(decorated_asciicast).to receive(:id).and_return(123)
    end

    it 'is an async script tag including asciicast id' do
      expect(subject).to match(script_regexp)
    end
  end

  describe '#show_admin_dropdown?' do
    subject { presenter.show_admin_dropdown? }

    before do
      allow(decorated_asciicast).to receive(:managable_by?).
        with(current_user) { managable }
    end

    context "when asciicast can't be managed by the user" do
      let(:managable) { false }

      it { should be(false) }
    end

    context "when asciicast can be managed by the user" do
      let(:managable) { true }

      it { should be(true) }
    end
  end

  describe '#show_description?' do
    subject { presenter.show_description? }

    before do
      allow(decorated_asciicast).to receive(:description) { description }
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
      allow(decorated_asciicast).to receive(:description) { 'i am description' }
    end

    it { should eq('i am description') }
  end

  describe '#show_other_asciicasts_by_author?' do
    subject { presenter.show_other_asciicasts_by_author? }

    before do
      allow(author).to receive(:asciicast_count) { count }
    end

    context "when user has more than 1 asciicast" do
      let(:count) { 2 }

      it { should be(true) }
    end

    context "when user doesn't have more than 1 asciicasts" do
      let(:count) { 1 }

      it { should be(false) }
    end
  end

  describe '#other_asciicasts_by_author' do
    subject { presenter.other_asciicasts_by_author }

    let(:others) { double('others', decorate: decorated_others) }
    let(:decorated_others) { double('decorated_others') }

    before do
      allow(author).to receive(:asciicasts_excluding).
        with(decorated_asciicast, 3) { others }
    end

    it "returns decorated asciicasts excluding the given one" do
      expect(subject).to be(decorated_others)
    end
  end

end
