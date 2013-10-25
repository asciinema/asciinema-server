class PagesController < ApplicationController

  layout 'pages'

  def show
    render params[:page]
  end

end
