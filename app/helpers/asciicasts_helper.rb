module AsciicastsHelper

  def player(asciicast, options = {})
    if params[:fallback]
      player_class = "AsciiIo.FallbackPlayer"
    else
      player_class = "window.Worker && $.browser.webkit ? " \
              "AsciiIo.Player : AsciiIo.FallbackPlayer"
    end

    if custom_renderer = params[:renderer]
      renderer_class = "AsciiIo.Renderer.#{custom_renderer.capitalize}"
    else
      renderer_class = "AsciiIo.Renderer.Pre"
    end

    render :partial => 'asciicasts/player', :locals => {
      player_class: player_class,
      cols: asciicast.terminal_columns,
      lines: asciicast.terminal_lines,
      speed: (options[:speed] || params[:speed] || 1).to_f,
      benchmark: !!params[:bm],
      asciicast_id: asciicast.id,
      renderer_class: renderer_class,
      auto_play: options.key?(:auto_play) ? !!options[:auto_play] : false,
      hud: options.key?(:hud) ? !!options[:hud] : true,
      snapshot: asciicast.snapshot
    }
  end
end
