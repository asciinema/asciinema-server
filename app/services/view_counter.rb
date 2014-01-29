class ViewCounter

  def increment(asciicast, storage)
    key = "a#{asciicast.id}"
    return if storage[key]

    Asciicast.increment_counter(:views_count, asciicast.id)
    asciicast.reload
    storage[key] = '1'
  end

end
