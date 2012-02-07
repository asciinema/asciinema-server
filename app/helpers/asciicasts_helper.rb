module AsciicastsHelper

  def player_data(asciicast)
    data = `bzip2 -d -c #{asciicast.stdout.path}`
    time = `bzip2 -d -c #{asciicast.stdout_timing.path}`

    data_hex_array = data.bytes.map { |b| '\x' + format('%02x', b) }
    var_data = "'#{data_hex_array.join}'"

    time_lines = time.lines.map do |line|
      delay, n = line.split
      "[#{delay.to_f}, #{n.to_i}]"
    end
    var_time = "[#{time_lines.join(',')}]"

    <<EOS.html_safe
<script>
  var data = #{var_data};
  var time = #{j var_time};
  var cols = #{asciicast.terminal_columns};
  var lines = #{asciicast.terminal_lines};
  $(function() {
    window.player = new AsciiIo.PlayerView({
      el: $('.player'),
      cols: cols,
      lines: lines,
      data: data,
      timing: time
    });

    window.player.play();
  });
</script>
EOS
  end

end
