class FrameDiffList
  include Enumerable

  delegate :each, :to => :frame_diffs

  def initialize(frames)
    @frames = frames
  end

  private

  attr_reader :frames

  def frame_diffs
    previous_frame = nil

    frames.map { |delay, frame|
      diff = frame.diff(previous_frame)
      previous_frame = frame
      [delay, diff]
    }
  end

end
