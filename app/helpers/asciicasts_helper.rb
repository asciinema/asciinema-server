module AsciicastsHelper

  def player_data(asciicast)
    data = File.read(asciicast.stdout.path).split("\n", 2)[1]
    time = File.read(asciicast.stdout_timing.path)

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
  $(function() { new AsciiIo.Player(cols, lines, data, time); });
</script>
EOS
  end

end
