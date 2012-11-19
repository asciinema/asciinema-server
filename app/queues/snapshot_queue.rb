class SnapshotQueue < GirlFriday::WorkQueue
  include Singleton

  def initialize
    super(:snapshot_queue, :size => 3) do |asciicast_id|
      SnapshotWorker.new.perform(asciicast_id)
    end
  end

  def self.push *args
    instance.push *args
  end
end
