class ViewCounter
  attr_reader :asciicast, :storage

  def initialize(asciicast, storage)
    @asciicast = asciicast
    @storage = storage
  end

  def increment
    unless storage[key]
      Asciicast.increment_counter(:views_count, asciicast.id)
      asciicast.reload
      storage[key] = '1'
    end
  end

  private

  def key
    @key ||= :"asciicast_#{asciicast.id}_viewed"
  end
end
