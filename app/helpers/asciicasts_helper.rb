module AsciicastsHelper

  def player(asciicast, options = PlaybackOptions.new)
    render 'asciicasts/player', asciicast: serialized_asciicast(asciicast),
                                options:   options
  end

  # TODO: move to AsciicastDecorator
  def link_to_delete_asciicast(name, asciicast)
    link_to name, asciicast_path(asciicast), :method => :delete,
      :data => { :confirm => 'Really delete this asciicast?' }
  end

  private

  def serialized_asciicast(asciicast)
    AsciicastSerializer.new(asciicast).to_json
  end

end
