require 'rails_helper'

describe PagesController do

  describe '#show' do
    before do
      get :show, page: :privacy, use_route: :privacy
    end

    it 'renders template with a given name' do
      should render_template(:privacy)
    end
  end

end
