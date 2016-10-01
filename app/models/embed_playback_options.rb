class EmbedPlaybackOptions < PlaybackOptions
  attribute :autoplay, Boolean, default: false
  attribute :preload,  Boolean, default: false
end
