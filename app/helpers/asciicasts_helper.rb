module AsciicastsHelper

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

    window.player.play();
  });
</script>
EOS
  end

end
