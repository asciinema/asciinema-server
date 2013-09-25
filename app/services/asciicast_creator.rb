class AsciicastCreator

  def create(attributes)
    attributes = AsciicastParams.new(attributes).to_h
    asciicast = Asciicast.create!(attributes, without_protection: true)
    AsciicastWorker.perform_async(asciicast.id)

    asciicast
  end

end
