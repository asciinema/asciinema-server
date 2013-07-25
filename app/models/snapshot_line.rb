class SnapshotLine

  attr_reader :fragments

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

end
