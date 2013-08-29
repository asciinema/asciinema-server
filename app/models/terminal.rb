class Terminal

  def initialize(width, height)
    @screen = TSM::Screen.new(width, height)
    @vte = TSM::Vte.new(@screen)
  end

  def feed(data)
    vte.input(data)
  end

  def snapshot
    lines = []

    screen.draw do |x, y, char, screen_attribute|
      assign_cell(lines, x, y, char, screen_attribute)
    end

    lines
  end

  def release
    screen.release
    vte.release
  end

  private

  attr_reader :screen, :vte

  def assign_cell(lines, x, y, char, screen_attribute)
    line = lines[y] ||= []
    line[x] = [sanitize_char(char), attributes_hash(screen_attribute)]
  end

  def sanitize_char(char)
    char.
      encode('UTF-16', :invalid => :replace, :undef => :replace,
                       :replace => "\001").
      encode('UTF-8').gsub(/\001+/, '?').
      first
  end

  def attributes_hash(screen_attribute)
    attrs = {}

    [:fg, :bg, :bold?, :underline?, :inverse?, :blink?].each do |name|
      assign_attr(attrs, screen_attribute, name)
    end

    attrs
  end

  def assign_attr(attrs, screen_attribute, name)
    value = screen_attribute.public_send(name)

    if value
      key = name.to_s.sub('?', '').to_sym
      attrs[key] = value
    end
  end

end
