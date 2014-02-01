require 'spec_helper'

describe UserPresenter do

  describe '.build' do
    subject { described_class.build(user, current_user, page, per_page) }

    let(:user) { double('user', decorate: decorated_user) }
    let(:decorated_user) { double('decorated_user') }
    let(:current_user) { double('current_user') }
    let(:page) { 2 }
    let(:per_page) { 5 }

    it "builds presenter instance with given user decorated" do
      expect(subject.user).to be(decorated_user)
    end

    it "builds presenter instance with given current_user" do
      expect(subject.current_user).to be(current_user)
    end

    it "builds presenter instance with given page" do
      expect(subject.page).to eq(2)
    end

    context "when page is nil" do
      let(:page) { nil }

      it "builds presenter instance with page = 1" do
        expect(subject.page).to eq(1)
      end
    end

    it "builds presenter instance with given per_page" do
      expect(subject.per_page).to eq(5)
    end

    context "when per_page is nil" do
      let(:per_page) { nil }

      it "builds presenter instance with per_page = PER_PAGE" do
        expect(subject.per_page).to eq(described_class::PER_PAGE)
      end
    end
  end

  let(:presenter) { described_class.new(user, current_user, page, per_page) }
  let(:user) { double('user', nickname: 'cartman') }
  let(:current_user) { double('current_user') }
  let(:page) { 2 }
  let(:per_page) { 5 }

  let(:view_context) {
    controller = ApplicationController.new
    controller.request = ActionController::TestRequest.new
    controller.view_context
  }

  describe '#title' do
    subject { presenter.title }

    it { should eq("cartman's profile") }
  end

  describe '#user_full_name' do
    subject { presenter.user_full_name }

    before do
      allow(user).to receive(:full_name) { 'E.C.' }
    end

    it { should eq('E.C.') }
  end

  describe '#user_joined_at' do
    subject { presenter.user_joined_at }

    before do
      allow(user).to receive(:joined_at) { 'Jan 1, 1970' }
    end

    it { should eq('Jan 1, 1970') }
  end

  describe '#user_avatar_image_tag' do
    subject { presenter.user_avatar_image_tag }

    before do
      allow(user).to receive(:avatar_image_tag) { '<img...>' }
    end

    it { should eq('<img...>') }
  end

  describe '#show_settings?' do
    subject { presenter.show_settings? }

    before do
      allow(user).to receive(:editable_by?).with(current_user) { :right }
    end

    it { should eq(:right) }
  end

  describe '#asciicast_count_text' do
    subject { presenter.asciicast_count_text(view_context) }

    before do
      allow(user).to receive(:asciicast_count) { 3 }
    end

    it { should eq('3 asciicasts by cartman') }
  end

  describe '#user_nickname' do
    subject { presenter.user_nickname }

    it { should eq('cartman') }
  end

  describe '#asciicasts' do
    subject { presenter.asciicasts }

    let(:collection) { [asciicast] }
    let(:asciicast) { double('asciicast', decorate: double(title: 'quux')) }

    before do
      allow(user).to receive(:paged_asciicasts) { collection }
    end

    it "gets user's asciicasts paged" do
      subject

      expect(user).to have_received(:paged_asciicasts).with(2, 5)
    end

    it "wraps the asciicasts with paginating decorator" do
      expect(subject).to respond_to(:current_page)
      expect(subject).to respond_to(:total_pages)
      expect(subject).to respond_to(:limit_value)
      expect(subject.first.title).to eq('quux')
    end
  end

  describe '#current_users_profile?' do
    subject { presenter.current_users_profile? }

    context "when current_user is the same user" do
      let(:current_user) { user }

      it { should be(true) }
    end

    context "when current_user is a different user" do
      let(:current_user) { double('other_user') }

      it { should be(false) }
    end

    context "when current_user is nil" do
      let(:current_user) { nil }

      it { should be_falsy }
    end
  end

end
