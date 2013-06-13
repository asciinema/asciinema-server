require 'spec_helper'

shared_examples_for 'guest user trying to modify' do
  it { should redirect_to(login_path) }
  specify { flash[:notice].should =~ /login first/ }
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
    let(:asciicasts) { [double('asciicast')] }
    let(:page) { double('page').to_s }

    before do
      Asciicast.should_receive(:newest_paginated).
        with(page, an_instance_of(Fixnum)).and_return(asciicasts)

      PaginatingDecorator.should_receive(:new).with(asciicasts).
        and_return(asciicasts)

      get :index, :page => page
    end

    it { should be_success }
    specify { assigns(:asciicasts).should == asciicasts }
    specify { assigns(:category_name).should =~ /^All/ }
    specify { assigns(:current_category).should == :all }
  end

  describe '#popular' do
    let(:asciicasts) { [double('asciicast')] }
    let(:page) { double('page').to_s }

    before do
      Asciicast.should_receive(:popular_paginated).
        with(page, an_instance_of(Fixnum)).and_return(asciicasts)

      PaginatingDecorator.should_receive(:new).with(asciicasts).
        and_return(asciicasts)

      get :popular, :page => page
    end

    it { should be_success }
    specify { assigns(:asciicasts).should == asciicasts }
    specify { assigns(:category_name).should =~ /^Popular/ }
    specify { assigns(:current_category).should == :popular }
  end

  describe '#show' do
    before do
      Asciicast.should_receive(:find).and_return(asciicast)

      asciicast.title = 'some tit'
    end

    context 'for html request' do
      let(:view_counter) { mock('view_counter') }

      before do
        AsciicastDecorator.should_receive(:new).with(asciicast).
          and_return(asciicast)
        ViewCounter.should_receive(:new).with(asciicast, cookies).
          and_return(view_counter)
        view_counter.should_receive(:increment)

        get :show, :id => asciicast.id, :format => :html
      end

      it { should be_success }
      specify { assigns(:asciicast).should == asciicast }
      specify { assigns(:title).should == asciicast.title }
    end

    context 'for json request' do
      let(:asciicast) { FactoryGirl.build(:asciicast, :id => 666) }

      before do
        AsciicastJSONDecorator.should_receive(:new).with(asciicast).
          and_return(asciicast)
        ViewCounter.should_not_receive(:new)

        get :show, :id => asciicast.id, :format => :json
      end

      it { should be_success }
    end

    context 'for js request' do
      let(:asciicast) { FactoryGirl.build(:asciicast, :id => 666) }

      before do
        ViewCounter.should_not_receive(:new)

        get :show, :id => asciicast.id, :format => :js
      end

      it { should be_success }
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
