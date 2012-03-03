class AsciicastsController < ApplicationController
  respond_to :html, :json

  def index
    @asciicasts = Asciicast.order("created_at DESC")
  end

  def show
    @asciicast = Asciicast.find(params[:id])
    respond_with @asciicast
  end

end
