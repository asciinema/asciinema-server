class Cursor

  attr_reader :x, :y, :visible

  def initialize(x, y, visible)
    @x, @y, @visible = x, y, visible
  end

  def diff(other)
    diff = {}
    diff[:x] = x if other && x != other.x || other.nil?
    diff[:y] = y if other && y != other.y || other.nil?
    diff[:visible] = visible if other && visible != other.visible || other.nil?

    diff
  end

end
