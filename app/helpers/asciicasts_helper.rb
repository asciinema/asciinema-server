module AsciicastsHelper

  def player(asciicast, options = PlaybackOptions.new)
    render 'asciicasts/player', asciicast: serialized_asciicast(asciicast),
                                options:   options
  end

  private

  def serialized_asciicast(asciicast)
    AsciicastSerializer.new(asciicast).to_json
  end

end
