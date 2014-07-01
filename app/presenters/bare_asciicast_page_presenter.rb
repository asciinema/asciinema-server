class BareAsciicastPagePresenter

  attr_reader :asciicast, :playback_options

  def self.build(asciicast, playback_options)
    decorated_asciicast = asciicast.decorate

    playback_options = {
      'theme' =>  decorated_asciicast.theme_name
    }.merge(playback_options)

    new(decorated_asciicast, PlaybackOptions.new(playback_options))
  end

  def initialize(asciicast, playback_options)
    @asciicast = asciicast
    @playback_options = playback_options
  end

  def asciicast_id
    asciicast.id
  end

end
