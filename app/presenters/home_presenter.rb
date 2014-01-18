class HomePresenter

  def asciicast
    @asciicast ||= get_asciicast
  end

  def latest_asciicasts
    Asciicast.latest_limited(3).decorate
  end

  def featured_asciicasts
    Asciicast.random_featured_limited(3).decorate
  end

  private

  def get_asciicast
    asciicast = CFG.home_asciicast

    asciicast && asciicast.decorate
  end

end
