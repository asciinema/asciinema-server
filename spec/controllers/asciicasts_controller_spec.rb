require 'rails_helper'

shared_examples_for 'guest user trying to modify' do
  it { should redirect_to(new_login_path) }
  specify { expect(flash[:notice]).to match(/log in to proceed/) }
end

shared_examples_for 'non-owner user trying to modify' do
  it { should redirect_to(root_path) }
  specify { expect(flash[:alert]).to match(/can't/) }
end

describe AsciicastsController do

  let(:user) { stub_model(User, username: 'nick') }
  let(:asciicast) { stub_model(Asciicast, :id => 666) }

  subject { response }

  describe '#index' do
    let(:asciicast_list_presenter) { double('asciicast_list_presenter') }

    before do
      allow(controller).to receive(:render)
      allow(BrowsePagePresenter).to receive(:build).
        with('featured', 'recency', '2') { asciicast_list_presenter }

      get :index, category: 'featured', order: 'recency', page: '2'
    end

    it { should be_success }

    it "renders template with BrowsePagePresenter as page" do
      expect(controller).to have_received(:render).
        with(locals: { page: asciicast_list_presenter })
    end
  end

  describe '#show' do
    let(:view_counter) { double('view_counter', :increment => nil) }

    before do
      allow(controller).to receive(:view_counter) { view_counter }
      expect(Asciicast).to receive(:find_by_id_or_secret_token!).and_return(asciicast)
    end

    let(:asciicast_presenter) { double('asciicast_presenter') }
    let(:user) { double('user') }

    before do
      allow(controller).to receive(:render)
      allow(controller).to receive(:current_user) { user }
      allow(AsciicastPagePresenter).to receive(:build).
        with(controller, asciicast, user, hash_including('speed' => '3.0')).
        and_return(asciicast_presenter)

      get :show, id: asciicast.id, format: :html, speed: 3.0
    end

    it { should be_success }

    it 'should be counted as a visit' do
      expect(view_counter).to have_received(:increment).
        with(asciicast, cookies)
    end

    it "renders template with AsciicastPagePresenter as page" do
      expect(controller).to have_received(:render).
        with(locals: { page: asciicast_presenter })
    end
  end

  describe '#edit' do
    let(:make_request) { get :edit, :id => asciicast.id }

    before do
      expect(Asciicast).to receive(:find_by_id_or_secret_token!).and_return(asciicast)
      asciicast.user = user
    end

    context 'for owner user' do
      before do
        login_as user
        make_request
      end

      it { should be_success }
    end

    context 'for guest user' do
      before do
        make_request
      end

      it_should_behave_like 'guest user trying to modify'
    end

    context 'for other user' do
      before do
        login_as stub_model(User)
        make_request
      end

      it_should_behave_like 'non-owner user trying to modify'
    end
  end

  describe '#update' do
    let(:make_request) {
      put :update, id: asciicast.id, asciicast: { title: 'title'}
    }

    let(:asciicast_updater) { double(:asciicast_updater) }

    before do
      allow(controller).to receive(:asciicast_updater) { asciicast_updater }
      expect(Asciicast).to receive(:find_by_id_or_secret_token!).and_return(asciicast)
      asciicast.user = user
    end

    context 'for owner user' do
      before do
        login_as user
      end

      context 'when update succeeds' do
        before do
          expect(asciicast_updater).to receive(:update).and_return(true)
          make_request
        end

        it { should redirect_to(asciicast_path(asciicast)) }
        specify { expect(flash[:notice]).to match(/was updated/) }
      end

      context 'when update fails' do
        before do
          expect(asciicast_updater).to receive(:update).and_return(false)
          make_request
        end

        it { should render_template(:edit) }
      end
    end

    context 'for guest user' do
      before do
        make_request
      end

      it_should_behave_like 'guest user trying to modify'
    end

    context 'for other user' do
      before do
        login_as stub_model(User)
        make_request
      end

      it_should_behave_like 'non-owner user trying to modify'
    end
  end

  describe '#destroy' do
    let(:make_request) { delete :destroy, :id => asciicast.id }

    before do
      expect(Asciicast).to receive(:find_by_id_or_secret_token!).and_return(asciicast)
      asciicast.user = user
    end

    context 'for owner user' do
      before do
        login_as user
      end

      context 'when destroy succeeds' do
        before do
          expect(asciicast).to receive(:destroy).and_return(true)
          make_request
        end

        it { should redirect_to(public_profile_path(username: 'nick')) }
        specify { expect(flash[:notice]).to match(/was deleted/) }
      end

      context 'when destroy fails' do
        before do
          expect(asciicast).to receive(:destroy).and_return(false)
          make_request
        end

        it { should redirect_to(asciicast_path(asciicast)) }
        specify { expect(flash[:alert]).to match(/again/) }
      end
    end

    context 'for guest user' do
      before do
        make_request
      end

      it_should_behave_like 'guest user trying to modify'
    end

    context 'for other user' do
      before do
        login_as stub_model(User)
        make_request
      end

      it_should_behave_like 'non-owner user trying to modify'
    end
  end

end
