class AsciicastsController < ApplicationController

  def index
    @asciicasts = Asciicast.order("created_at DESC")
  end

  def show
    @asciicast = Asciicast.find(params[:id])
  end

end
