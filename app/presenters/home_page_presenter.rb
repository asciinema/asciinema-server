class HomePagePresenter

  attr_reader :playback_options

  def initialize
    @playback_options = PlaybackOptions.new(speed: 2.0)
  end

  def asciicast
    @asciicast ||= get_asciicast
  end

  def latest_asciicasts
    Asciicast.latest_limited(6).decorate
  end

  def featured_asciicasts
    Asciicast.random_featured_limited(6).decorate
  end

  def install_script_url
    "https://asciinema.org/install"
  end

  private

  def get_asciicast
    asciicast = CFG.home_asciicast

    asciicast && asciicast.decorate
  end

end
