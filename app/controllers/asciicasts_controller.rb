class AsciicastsController < ApplicationController

  def index
    @asciicast = Asciicast.find(params[:id])
  end

end
