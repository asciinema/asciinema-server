module AsciicastsHelper

  def player_script(asciicast, options = {})
    speed = (options[:speed] || 1).to_f
    benchmark = !!params[:bm]
    auto_play = options.key?(:auto_play) ? !!options[:auto_play] : false
    hud = options.key?(:hud) ? !!options[:hud] : true

    if custom_renderer = params[:renderer]
      renderer_class = "AsciiIo.Renderer.#{custom_renderer.capitalize}"
    else
      renderer_class = "AsciiIo.Renderer.Pre"
    end

    return <<EOS.html_safe
<script>
  $(function() {
    window.player = new AsciiIo.PlayerView({
      el: $('.player'),
      cols: #{asciicast.terminal_columns},
      lines: #{asciicast.terminal_lines},
      speed: #{speed},
      benchmark: #{benchmark},
      model: new AsciiIo.Asciicast({ id: #{asciicast.id} }),
      rendererClass: #{renderer_class},
      autoPlay: #{auto_play},
      hud: #{hud},
      snapshot: "#{j asciicast.snapshot.to_s}"
    });
  });
</script>
EOS
  end
end
