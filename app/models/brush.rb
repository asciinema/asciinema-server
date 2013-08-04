class Brush

  def initialize(attributes = {})
    @attributes = attributes.symbolize_keys
  end

  def ==(other)
    fg == other.fg &&
      bg == other.bg &&
      bold? == other.bold? &&
      underline? == other.underline? &&
      inverse? == other.inverse?
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
    attributes[:bg]
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

  def default?
    fg.nil? && bg.nil? && !bold? && !underline? && !inverse?
  end

  protected

  attr_reader :attributes

end
