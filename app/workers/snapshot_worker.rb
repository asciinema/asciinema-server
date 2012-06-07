require 'tempfile'

class SnapshotWorker
  def perform(asciicast_id)
    begin
      @asciicast = Asciicast.find(asciicast_id)

      prepare_files
      convert_to_typescript

      delay = (@asciicast.duration / 2).to_i
      delay = 30 if delay > 30
      snapshot = capture_terminal(delay)

      @asciicast.snapshot = snapshot
      @asciicast.save!

    rescue ActiveRecord::RecordNotFound
      # oh well...

    ensure
      cleanup
    end
  end

  def prepare_files
    if RUBY_VERSION < '1.9'
      in_data_file = Tempfile.new('asciiio-data')
    else
      in_data_file = Tempfile.new('asciiio-data', :encoding => 'ascii-8bit')
    end
    in_data_file.write(@asciicast.stdout.read)
    in_data_file.close
    @in_data_path = in_data_file.path

    if RUBY_VERSION < '1.9'
      in_timing_file = Tempfile.new('asciiio-timing')
    else
      in_timing_file = Tempfile.new('asciiio-timing', :encoding => 'ascii-8bit')
    end
    in_timing_file.write(@asciicast.stdout_timing.read)
    in_timing_file.close
    @in_timing_path = in_timing_file.path

    @out_data_path = @in_data_path + '.ts'
    @out_timing_path = @in_timing_path + '.ts'
  end

  def convert_to_typescript
    system "bash -c './script/convert-to-typescript.sh " +
           "#{@in_data_path} #{@in_timing_path} " +
           "#{@out_data_path} #{@out_timing_path}'"
    raise "Can't convert asciicast ##{@asciicast.id} to typescript" if $? != 0
  end

  def capture_terminal(delay)
    capture_command =
      "scriptreplay #{@out_timing_path} #{@out_data_path}; sleep 10"

    command = "bash -c 'ASCIICAST_ID=#{@asciicast.id} " +
              "COLS=#{@asciicast.terminal_columns} " +
              "LINES=#{@asciicast.terminal_lines} " +
              "COMMAND=\"#{capture_command}\" " +
              "DELAY=#{delay} ./script/capture.sh'"

    lines = []
    pid, stdin, stdout, stderr = open4(command)

    while !stdout.eof?
      lines << stdout.readline
    end

    Process.waitpid pid
    status = $?.exitstatus

    raise "Can't capture output of asciicast ##{@asciicast.id}" if status != 0

    lines.join('')
  end

  def cleanup
    FileUtils.rm_f([
      @in_data_path,
      @in_timing_path,
      @out_data_path,
      @out_timing_path
    ].compact)
  end
end
