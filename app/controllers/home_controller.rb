class HomeController < ApplicationController
  def show
    @asciicasts = Asciicast.order("created_at DESC").limit(10)
    offset = (Asciicast.featured.count * rand).to_i
    @asciicast  = Asciicast.featured.offset(offset).first || @asciicasts.first
  end
end
