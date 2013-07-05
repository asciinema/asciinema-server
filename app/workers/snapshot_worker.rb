class SnapshotWorker
  include Sidekiq::Worker

  def perform(asciicast_id)
    AsciicastSnapshotter.new(asciicast_id).run
  end
end
