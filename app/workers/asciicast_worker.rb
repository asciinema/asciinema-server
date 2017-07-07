class AsciicastWorker

  include Sidekiq::Worker

  def perform(asciicast_id)
    asciicast = Asciicast.find(asciicast_id)

    if asciicast.version == 0
      AsciicastFramesFileUpdater.new.update(asciicast)
    end

  rescue ActiveRecord::RecordNotFound
    # oh well...
  end

end
