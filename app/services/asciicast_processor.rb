class AsciicastProcessor

  def process(asciicast)
    AsciicastSnapshotUpdater.new.update(asciicast)

    if asciicast.version == 0
      AsciicastFramesFileUpdater.new.update(asciicast)
    end
  end

end
