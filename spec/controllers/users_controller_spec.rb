require 'spec_helper'

describe UsersController do

  describe "POST create" do
    let(:user) { mock_model(User) }

    before do
      User.stub(:new).and_return(user)
    end

    context "when user saved" do
      before do
        user.stub!(:save => true)
      end

      it "sets current_user" do
        post :create
        @controller.current_user.should_not be_nil
      end

      it "redirects back" do
        post :create
        should redirect_to(root_url)
      end

    end

    context "when not valid data" do
      before do
        user.stub!(:save => false)
      end

      it "renders user/new" do
        post :create
        should render_template('users/new')
      end

    end

  end
end
