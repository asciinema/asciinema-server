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
  });
</script>
EOS
  end

end
