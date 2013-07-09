class Snapshot
  attr_reader :lines

  def initialize(lines = [])
    @lines = lines
  end

  def ==(other)
    other.lines == lines
  end

  class Serializer
    def dump(snapshot)
      YAML.dump(snapshot.lines)
    end

    def load(value)
      value.present? ? Snapshot.new(YAML.load(value)) : Snapshot.new
    end
  end
end
