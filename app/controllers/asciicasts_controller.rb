class AsciicastsController < ApplicationController
  PER_PAGE = 20

  respond_to :html, :json

  def index
    @asciicasts = Asciicast.order("created_at DESC").page(params[:page]).per(PER_PAGE)
  end

  def show
    @asciicast = Asciicast.find(params[:id])
    respond_with @asciicast
  end

end
