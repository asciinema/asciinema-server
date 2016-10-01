class PlaybackOptions

  class Time < Virtus::Attribute
    def coerce(value)
      value = value.presence

      if value
        smh = value.strip.sub("m", ":0").split(":").reverse
        smh[0].to_i + smh[1].to_i * 60 + smh[2].to_i * 3600
      end
    end
  end

  include Virtus.model

  attribute :speed,     Float,   default: 1.0
  attribute :size,      String,  default: 'small'
  attribute :autoplay,  Boolean
  attribute :loop,      Boolean, default: false
  attribute :preload,   Boolean, default: true
  attribute :benchmark, Boolean, default: false
  attribute :theme,     String,  default: Theme::DEFAULT
  attribute :t,         Time
  attribute :v0,        Boolean, default: false
  attribute :poster,    String

  def autoplay()
    ap = super
    ap.nil? ? !!t : ap
  end

  def poster()
    p = super

    if !p && t && t > 0 && !autoplay
      "npt:#{t}"
    else
      p
    end
  end

end
