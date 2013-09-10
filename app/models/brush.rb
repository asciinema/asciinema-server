class Brush

  ALLOWED_ATTRIBUTES = [:fg, :bg, :bold, :underline, :inverse, :blink]

  def initialize(attributes = {})
    @attributes = attributes.symbolize_keys
  end

  def ==(other)
    fg == other.fg &&
      bg == other.bg &&
      bold? == other.bold? &&
      underline? == other.underline? &&
      inverse? == other.inverse? &&
      blink? == other.blink?
  end

  def fg
    code = attributes[:fg]

    if code
      if code < 8 && bold?
        code += 8
      end
    end

    code
  end

  def bg
    code = attributes[:bg]

    if code
      if code < 8 && blink?
        code += 8
      end
    end

    code
  end

  def bold?
    !!attributes[:bold]
  end

  def underline?
    !!attributes[:underline]
  end

  def inverse?
    !!attributes[:inverse]
  end

  def blink?
    !!attributes[:blink]
  end

  def default?
    fg.nil? && bg.nil? && !bold? && !underline? && !inverse? && !blink?
  end

  def as_json(*)
    attributes.slice(*ALLOWED_ATTRIBUTES)
  end

  protected

  attr_reader :attributes

end
