class SnapshotLine
  include Enumerable

  delegate :each, :to => :fragments

  def self.build(blocks)
    fragments = blocks.map { |block|
      SnapshotFragment.new(block[0], Brush.new(block[1]))
    }

    new(fragments)
  end

  def initialize(fragments)
    @fragments = fragments
  end

  def ==(other)
    other.fragments == fragments
  end

  def crop(size)
    new_fragments = []
    current_size = 0

    fragments.each do |fragment|
      break if current_size == size

      if current_size + fragment.size > size
        fragment = fragment.crop(size - current_size)
      end

      new_fragments << fragment
      current_size += fragment.size
    end

    self.class.new(new_fragments)
  end

  def empty?
    fragments.all?(&:empty?)
  end

  protected

  attr_reader :fragments

end
