class Snapshot
  include Enumerable

  delegate :each, :to => :lines

  def self.build(lines)
    lines = lines.map { |fragments| SnapshotLine.build(fragments) }

    new(lines)
  end

  def initialize(lines = [])
    @lines = lines
  end

  def ==(other)
    other.lines == lines
  end

  def crop(width, height)
    min_height = [height, lines.size].min
    new_lines = lines.drop(lines.size - min_height).map { |line| line.crop(width) }

    self.class.new(new_lines)
  end

  def rstrip
    i = lines.size - 1

    while i >= 0 && lines[i].empty?
      i -= 1
    end

    new_lines = i > -1 ? lines[0..i] : []

    self.class.new(new_lines)
  end

  def expand(height)
    new_lines = lines

    while new_lines.size < height
      new_lines << []
    end

    self.class.new(new_lines)
  end

  protected

  attr_reader :lines

end
