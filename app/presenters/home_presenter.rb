class HomePresenter

  def asciicast
    @asciicast ||= get_asciicast
  end

  def latest_asciicasts
    AsciicastDecorator.decorate_collection(Asciicast.latest_limited(3))
  end

  def featured_asciicasts
    AsciicastDecorator.decorate_collection(Asciicast.random_featured_limited(3))
  end

  private

  def get_asciicast
    asciicast = CFG.home_asciicast

    asciicast && AsciicastDecorator.new(asciicast)
  end

end
