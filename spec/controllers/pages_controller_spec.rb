require 'rails_helper'

describe PagesController do

  describe '#show' do
    before do
      get :show, page: :tos, use_route: :tos
    end

    it 'renders template with a given name' do
      should render_template(:tos)
    end
  end

end
