class StaticPagesController < ApplicationController
  def show
    render params[:page]
  end
end
