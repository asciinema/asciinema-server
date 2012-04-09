require 'spec_helper'

describe StaticPagesController do

  describe '#show' do
    it 'renders template named by params[:page]' do
      get :show, :page => 'manual'
      response.should render_template('manual')
    end
  end

end
