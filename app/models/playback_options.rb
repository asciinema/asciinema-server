class PlaybackOptions

  include Virtus.model

  attribute :speed,     Float,   default: 1.0
  attribute :font_size, String,  default: 'small'
  attribute :autoplay,  Boolean, default: false
  attribute :max_width, Integer
  attribute :hide_hud,  Boolean, default: false
  attribute :fallback,  Boolean, default: false
  attribute :renderer,  String,  default: 'Pre'
  attribute :benchmark, Boolean, default: false

  def player_class
    if fallback
      "Asciinema.FallbackPlayer"
    else
      "window.Worker ? Asciinema.Player : Asciinema.FallbackPlayer"
    end
  end

  def renderer_class
    "Asciinema.Renderer.#{renderer}"
  end

end
