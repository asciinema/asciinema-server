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

  def as_json(*)
    opts = {
      speed: speed,
      autoPlay: autoplay.nil? ? !!t : autoplay,
      loop: loop,
      preload: preload,
      fontSize: size,
      theme: theme,
    }

    if t
      opts = opts.merge(startAt: t)
    end

    opts
  end

end
