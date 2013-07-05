class SnapshotWorker
  def perform(asciicast_id)
    AsciicastSnapshotter.new(asciicast_id).run
  end
end
