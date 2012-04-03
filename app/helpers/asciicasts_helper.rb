module AsciicastsHelper

  def asciicast_title(asciicast)
    if asciicast.title.present?
      asciicast.title
    elsif asciicast.command.present?
      "$ #{asciicast.command}"
    else
      "##{asciicast.id}"
    end
  end

  def profile_link(asciicast, options = {})
    if asciicast.user
      if options[:avatar]
        img = avatar_img(asciicast.user) + " "
      else
        img = ""
      end

      link_to img + "~#{asciicast.user.nickname}", profile_path(asciicast.user)
    else
      if asciicast.username.present?
        "~#{asciicast.username}"
      else
        "anonymous"
      end
    end
  end

  def asciicast_time(asciicast)
    time_ago_in_words(asciicast.created_at) + " ago"
  end

  def player_script(asciicast, options = {})
    speed = (params[:speed] || 1).to_f
    benchmark = !!params[:bm]
    auto_play = options.key?(:auto_play) ? !!options[:auto_play] : false

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
      autoPlay: #{auto_play}
    });
  });
</script>
EOS
  end
end
