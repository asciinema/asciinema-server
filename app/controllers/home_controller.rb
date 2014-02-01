class HomeController < ApplicationController

  def show
    render locals: { page: HomePagePresenter.new }
  end

end
