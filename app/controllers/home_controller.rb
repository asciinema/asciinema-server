class HomeController < ApplicationController

  def show
    render locals: {
      asciicast:           asciicast,
      featured_asciicasts: featured_asciicasts,
      latest_asciicasts:   latest_asciicasts
    }
  end

  private

  def asciicast
    id = CFG.home_cast_id

    asciicast = if id
      asciicast_repository.find(id)
    else
      asciicast_repository.last
    end

    asciicast && asciicast.decorate
  end

  def latest_asciicasts
    asciicast_repository.latest_limited(3).decorate
  end

  def featured_asciicasts
    asciicast_repository.random_featured_limited(3).decorate
  end

  def asciicast_repository
    Asciicast
  end

end
