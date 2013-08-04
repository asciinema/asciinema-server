require 'base64'

class AsciicastJSONDecorator < ApplicationDecorator

  def as_json(*args)
    data = model.as_json(*args)
    data['escaped_stdout_data'] = escaped_stdout_data
    data['stdout_timing_data'], saved_time = stdout_timing_data
    data['duration'] = data['duration'] - saved_time

    data
  end

  def escaped_stdout_data
    if data = stdout.data
      Base64.strict_encode64(data)
    else
      nil
    end
  end

  def stdout_timing_data
    saved_time = 0

    timing = stdout.timing.map do |line|
      delay, size = line

      if time_compression && delay > Asciicast::MAX_DELAY
        saved_time += (delay - Asciicast::MAX_DELAY)
        delay = Asciicast::MAX_DELAY
      end

      [delay, size]
    end

    [timing, saved_time]
  end

end
