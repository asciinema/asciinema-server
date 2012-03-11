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
    end
  end

  def asciicast_time(asciicast)
    time_ago_in_words(asciicast.created_at) + " ago"
  end

  def player_script(asciicast, options = {})
    auto_play = options.key?(:auto_play) ? !!options[:auto_play] : false

    return <<EOS.html_safe
<script>
  $(function() {
    window.player = new AsciiIo.PlayerView({
      el: $('.player'),
      cols: #{asciicast.terminal_columns},
      lines: #{asciicast.terminal_lines},
      model: new AsciiIo.Asciicast({ id: #{asciicast.id} }),
      autoPlay: #{auto_play}
    });
  });
</script>
EOS
  end

  def random_description
    ("<p>" + Faker::Lorem.sentences(6).join + "</p>").html_safe
  end
end
