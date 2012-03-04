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

  def asciicast_author(asciicast)
    if asciicast.user
      link_to avatar_img(asciicast.user) + " #{asciicast.user.nickname}", '#'
    end
  end

  def asciicast_time(asciicast)
    time_ago_in_words(asciicast.created_at) + " ago"
  end

  def player_script(asciicast)
    return <<EOS.html_safe
<script>
  $(function() {
    window.player = new AsciiIo.PlayerView({
      el: $('.player'),
      cols: #{asciicast.terminal_columns},
      lines: #{asciicast.terminal_lines},
      model: new AsciiIo.Asciicast({ id: #{asciicast.id} })
    });
  });
</script>
EOS
  end

end
