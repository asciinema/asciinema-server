class AsciicastProcessor

  def process(asciicast)
    AsciicastSnapshotUpdater.new.update(asciicast)
    AsciicastFramesFileUpdater.new.update(asciicast)
  end

end
