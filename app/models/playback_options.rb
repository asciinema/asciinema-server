class PlaybackOptions

  include Virtus.model

  attribute :speed,     Float,   default: 1.0
  attribute :size,      String,  default: 'small'
  attribute :autoplay,  Boolean, default: false
  attribute :hide_hud,  Boolean, default: false
  attribute :renderer,  String,  default: 'Pre'
  attribute :benchmark, Boolean, default: false

end
