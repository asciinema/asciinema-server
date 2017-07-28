require 'rails_helper'

describe SessionsController do

  describe "#destroy" do
    before do
      allow(controller).to receive(:current_user=)

      get :destroy
    end

    it "sets current_user to nil" do
      expect(controller).to have_received(:current_user=).with(nil)
    end

    it "redirects to root_path with a notice" do
      expect(flash[:notice]).to_not be_blank
      should redirect_to(root_path)
    end
  end

end
