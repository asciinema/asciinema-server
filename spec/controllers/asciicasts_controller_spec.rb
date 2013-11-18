require 'spec_helper'

shared_examples_for 'guest user trying to modify' do
  it { should redirect_to(login_path) }
  specify { flash[:notice].should =~ /sign in to proceed/ }
end

shared_examples_for 'non-owner user trying to modify' do
  it { should redirect_to(asciicast_path(asciicast)) }
  specify { flash[:alert].should =~ /can't/ }
end

describe AsciicastsController do

  let(:user) { stub_model(User, :nickname => 'nick') }
  let(:asciicast) { stub_model(Asciicast, :id => 666) }

  subject { response }

  describe '#index' do
    let(:asciicast_list) { double('asciicast_list') }
    let(:decorated_asciicast_list) { double('decorated_asciicast_list') }

    before do
      allow(controller).to receive(:render)

      allow(AsciicastList).to receive(:new).
        with('featured', 'recency') { asciicast_list }
      allow(AsciicastListDecorator).to receive(:new).
        with(asciicast_list, '2') { decorated_asciicast_list }

      get :index, category: 'featured', order: 'recency', page: '2'
    end

    it { should be_success }

    it 'renders template with asciicast_list' do
      expect(controller).to have_received(:render).
        with(locals: { asciicast_list: decorated_asciicast_list })
    end
  end

  describe '#show' do
    let(:view_counter) { double('view_counter', :increment => nil) }

    before do
      allow(controller).to receive(:view_counter) { view_counter }
      Asciicast.should_receive(:find).and_return(asciicast)
      asciicast.title = 'some tit'
    end

    context 'for html request' do
      let(:asciicast_decorator) { double('decorator', :title => 'The Title') }

      before do
        allow(AsciicastDecorator).to receive(:new).with(asciicast).
          and_return(asciicast_decorator)

        get :show, :id => asciicast.id, :format => :html
      end

      it { should be_success }

      it 'should be counted as a visit' do
        expect(view_counter).to have_received(:increment).
          with(asciicast, cookies)
      end

      specify { assigns(:asciicast).should == asciicast_decorator }
      specify { assigns(:title).should == 'The Title' }
    end

    context 'for json request' do
      before do
        get :show, :id => asciicast.id, :format => :json
      end

      it { should be_success }

      it 'should not be counted as a visit' do
        expect(view_counter).to_not have_received(:increment)
      end
    end

    context 'for js request' do
      before do
        get :show, :id => asciicast.id, :format => :js
      end

      it { should be_success }

      it 'should not be counted as a visit' do
        expect(view_counter).to_not have_received(:increment)
      end
    end
  end

  describe '#edit' do
    let(:make_request) { get :edit, :id => asciicast.id }

    before do
      Asciicast.should_receive(:find).and_return(asciicast)
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
    let(:make_request) { put :update, :id => asciicast.id, :asciicast => { } }

    before do
      Asciicast.should_receive(:find).and_return(asciicast)
      asciicast.user = user
    end

    context 'for owner user' do
      before do
        login_as user
      end

      context 'when update succeeds' do
        before do
          asciicast.should_receive(:update_attributes).and_return(true)
          make_request
        end

        it { should redirect_to(asciicast_path(asciicast)) }
        specify { flash[:notice].should =~ /was updated/ }
      end

      context 'when update fails' do
        before do
          asciicast.should_receive(:update_attributes).and_return(false)
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
      Asciicast.should_receive(:find).and_return(asciicast)
      asciicast.user = user
    end

    context 'for owner user' do
      before do
        login_as user
      end

      context 'when destroy succeeds' do
        before do
          asciicast.should_receive(:destroy).and_return(true)
          make_request
        end

        it { should redirect_to(profile_path(user)) }
        specify { flash[:notice].should =~ /was deleted/ }
      end

      context 'when destroy fails' do
        before do
          asciicast.should_receive(:destroy).and_return(false)
          make_request
        end

        it { should redirect_to(asciicast_path(asciicast)) }
        specify { flash[:alert].should =~ /again/ }
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
