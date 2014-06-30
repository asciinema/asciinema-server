class PlaybackOptions

  include Virtus.model

  attribute :speed,     Float,   default: 1.0
  attribute :size,      String,  default: 'small'
  attribute :autoplay,  Boolean, default: false
  attribute :benchmark, Boolean, default: false
  attribute :theme,     String,  default: Theme::DEFAULT

end
