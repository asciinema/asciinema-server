module AsciicastsHelper

  def player(asciicast, options = PlaybackOptions.new)
    render :partial => 'asciicasts/player', :locals => {
      asciicast:       serialized_asciicast(asciicast),
      player_class:    options.player_class,
      speed:           options.speed,
      benchmark:       options.benchmark,
      container_width: options.max_width,
      renderer_class:  options.renderer_class,
      auto_play:       options.autoplay,
      hud:             !options.hide_hud,
      size:            options.font_size,
    }
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
