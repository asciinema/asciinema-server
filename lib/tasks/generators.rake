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
  end
end
