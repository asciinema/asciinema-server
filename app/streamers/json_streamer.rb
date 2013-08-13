class JsonStreamer

  def initialize(object)
    @object = object
  end

  def each(&blk)
    yield '{'

    @object.each_with_index do |key_value, i|
      key, value = key_value
      yield %("#{key}":)

      if value.respond_to?(:call)
        value.call do |v|
          yield v.to_s
        end
      else
        yield value.to_json
      end

      yield ',' unless i + 1 == @object.size
    end

    yield '}'
  end

end
