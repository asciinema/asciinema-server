SNAPSHOT_QUEUE = GirlFriday::WorkQueue.new(:snapshot, :size => 3) do |asciicast_id|
  SnapshotWorker.new.perform(asciicast_id)
end
