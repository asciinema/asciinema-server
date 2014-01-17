require 'spec_helper'

describe HomeController do

  describe '#show' do
    before do
      allow(controller).to receive(:render)
      get :show
    end

    it "renders template with HomePresenter as page" do
      expect(controller).to have_received(:render).
        with(locals: { page: kind_of(HomePresenter) })
    end
  end

end
