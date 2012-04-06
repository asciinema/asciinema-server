class HomeController < ApplicationController
  def show
    offset = (Asciicast.featured.count * rand).to_i
    @asciicast  = Asciicast.featured.offset(offset).first || @asciicasts.first
  end
end
