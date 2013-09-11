class AsciicastWorker

  include Sidekiq::Worker

  def perform(asciicast_id)
    asciicast = Asciicast.find(asciicast_id)
    AsciicastProcessor.new.process(asciicast)

  rescue ActiveRecord::RecordNotFound
    # oh well...
  end

end
