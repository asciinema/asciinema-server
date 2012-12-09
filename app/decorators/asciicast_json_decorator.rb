require 'base64'

class AsciicastJSONDecorator < ApplicationDecorator
  decorates :asciicast

  MAX_DELAY = 5.0

  def as_json(*args)
    data = model.as_json(*args)
    data['escaped_stdout_data'] = escaped_stdout_data
    data['stdout_timing_data'], saved_time = stdout_timing_data
    data['duration'] = data['duration'] - saved_time

    data
  end

  def escaped_stdout_data
    if data = stdout.read
      Base64.strict_encode64(data)
    else
      nil
    end
  end

  def stdout_timing_data
    saved_time = 0

    if file = stdout_timing.file
      f = IO.popen "bzip2 -d", "r+"
      f.write file.read
      f.close_write
      lines = f.readlines
      f.close

      data = lines.map do |line|
        delay, n = line.split
        delay = delay.to_f

        if time_compression && delay > MAX_DELAY
          saved_time += (delay - MAX_DELAY)
          delay = MAX_DELAY
        end

        [delay, n.to_i]
      end
    else
      data = nil
    end

    [data, saved_time]
  end
end
