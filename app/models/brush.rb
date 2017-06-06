class Brush

  ALLOWED_ATTRIBUTES = [:fg, :bg, :bold, :underline, :inverse, :blink]
  DEFAULT_FG_CODE = 7
  DEFAULT_BG_CODE = 0

  def initialize(attributes = {})
    @attributes = attributes.symbolize_keys
  end

  def ==(other)
    fg == other.fg &&
      bg == other.bg &&
      bold? == other.bold? &&
      underline? == other.underline? &&
      blink? == other.blink?
  end

  def fg
    inverse? ? bg_code || DEFAULT_BG_CODE : fg_code
  end

  def bg
    inverse? ? fg_code || DEFAULT_FG_CODE : bg_code
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

  def self.rgb_color?(col)
    col.is_a?(Enumerable)
  end

  def self.simple_color?(col)
    col.is_a?(Fixnum)
  end

  protected

  attr_reader :attributes

  private

  def fg_code
    calculate_code(:fg, bold?)
  end

  def bg_code
    calculate_code(:bg, blink?)
  end

  def calculate_code(attr_name, strong)
    code = attributes[attr_name]

    if Brush.simple_color?(code) && code < 8 && strong
      code += 8
    end

    code
  end

end
