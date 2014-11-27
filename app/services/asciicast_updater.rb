class AsciicastUpdater

  def update(asciicast, attributes)
    asciicast.attributes = attributes
    need_snapshot_update = asciicast.snapshot_at_changed?

    if asciicast.save
      if need_snapshot_update
        AsciicastSnapshotUpdater.new.update(asciicast)
      end

      true
    else
      false
    end
  end

end
