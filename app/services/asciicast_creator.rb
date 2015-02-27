class AsciicastCreator

  def create(attributes)
    asciicast = Asciicast.create!(attributes)
    AsciicastWorker.perform_async(asciicast.id)

    asciicast
  end

end
