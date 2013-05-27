class HomeController < ApplicationController
  before_filter :load_asciicast

  def show
    @title = "Share Your Terminal With No Fuss"

    if @asciicast
      @asciicast = AsciicastDecorator.new(@asciicast)
    end

    @asciicasts = AsciicastDecorator.decorate_collection(
      Asciicast.order("created_at DESC").limit(9).includes(:user)
    )
  end

  private

  def load_asciicast
    if id = CFG['HOME_CAST_ID']
      @asciicast = Asciicast.find(id)
    else
      @asciicast = Asciicast.order("created_at DESC").first
    end
  end
end
