class HomeController < ApplicationController

  def show
    render locals: { page: HomePresenter.new }
  end

end
