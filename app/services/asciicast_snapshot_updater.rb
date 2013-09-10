class AsciicastSnapshotUpdater

  def update(asciicast, at_seconds = asciicast.duration / 2)
    snapshot = generate_snapshot(asciicast, at_seconds)
    asciicast.update_attribute(:snapshot, snapshot)
  end

  private

  def generate_snapshot(asciicast, at_seconds)
    asciicast.with_terminal do |terminal|
      Film.new(asciicast.stdout, terminal).snapshot_at(at_seconds)
    end
  end

end
