require 'tempfile'

class ThumbnailWorker
  include Sidekiq::Worker

  def perform(asciicast_id)
    asciicast = Asciicast.find(asciicast_id)

    in_data_file = Tempfile.new('asciiio-data', :encoding => 'ascii-8bit')
    in_data_file.write(asciicast.stdout.read)
    in_data_file.close
    in_data_path = in_data_file.path

    in_timing_file = Tempfile.new('asciiio-timing', :encoding => 'ascii-8bit')
    in_timing_file.write(asciicast.stdout_timing.read)
    in_timing_file.close
    in_timing_path = in_timing_file.path

    out_data_path = in_data_path + '.ts'
    out_timing_path = in_timing_path + '.ts'

    if system "bash -c './script/convert-to-typescript.sh #{in_data_path} #{in_timing_path} #{out_data_path} #{out_timing_path}'"
      delay = (asciicast.duration / 2).to_i
      command = "scriptreplay #{out_timing_path} #{out_data_path}; sleep 10"
      puts '-' * 80
      system "bash -c 'ASCIICAST_ID=#{asciicast_id} COLS=#{asciicast.terminal_columns} LINES=#{asciicast.terminal_lines} COMMAND=\"#{command}\" DELAY=#{delay} THUMB_LINES=10 THUMB_COLS=20 ./script/thumbnail.sh'"
    else
      puts "failed"
    end
  end
end
