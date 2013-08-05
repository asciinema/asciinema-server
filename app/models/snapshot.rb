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

    while new_lines.size < height
      new_lines << []
    end

    self.class.new(new_lines)
  end

  protected

  attr_reader :lines

end
