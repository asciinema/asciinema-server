class Frame

  attr_reader :snapshot, :cursor

  def initialize(snapshot, cursor)
    @snapshot = snapshot
    @cursor = cursor
  end

  def diff(other)
    FrameDiff.new(snapshot_diff(other), cursor_diff(other))
  end

  private

  def snapshot_diff(other)
    snapshot.diff(other && other.snapshot)
  end

  def cursor_diff(other)
    cursor.diff(other && other.cursor)
  end

end
