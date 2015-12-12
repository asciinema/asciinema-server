namespace :asciinema do
  namespace :generate do
    desc "Generate frames files"
    task :frames => :environment do
      updater = AsciicastFramesFileUpdater.new

      Asciicast.where(stdout_frames: nil).find_each do |a|
        puts a.id
        updater.update(a)
      end
    end

    desc "Generate frames file and save it on disk"
    task :frames_file => :environment do
      input_filename = ENV['IN']
      output_filename = ENV['OUT']

      stdout = Stdout::SingleFile.new(input_filename)
      file_writer = JsonFileWriter.new
      asciicast = JSON.load(File.open(input_filename, 'r'))

      terminal = Terminal.new(asciicast['width'], asciicast['height'])

      File.open(output_filename, 'w') do |file|
        film = Film.new(stdout, terminal)
        file_writer.write_enumerable(file, film.frames)
      end

      terminal.release
    end
  end
end
