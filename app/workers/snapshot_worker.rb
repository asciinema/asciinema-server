class SnapshotWorker

  include Sidekiq::Worker

  def perform(asciicast_id)
    asciicast = Asciicast.find(asciicast_id)

    snapshot = SnapshotCreator.new.create(
      asciicast.terminal_columns,
      asciicast.terminal_lines,
      asciicast.stdout,
      asciicast.duration
    )

    asciicast.update_snapshot(snapshot)

  rescue ActiveRecord::RecordNotFound
    # oh well...
  end

end
