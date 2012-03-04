class HomeController < ApplicationController
  def show
    @asciicasts = Asciicast.order("created_at DESC").limit(10)
  end
end
