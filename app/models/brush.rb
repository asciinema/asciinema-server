class Brush
  attr_reader :attributes

  def initialize(attributes = {})
    @attributes = attributes
  end

  def fg
    attributes[:fg]
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
end
