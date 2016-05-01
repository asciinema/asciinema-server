class EmbedPlaybackOptions < PlaybackOptions
  attribute :autoplay, Boolean, default: false

  def as_json(*)
    if !poster && t && t > 0
      super.merge({ poster: "npt:#{t}" })
    else
      super
    end
  end

end
