class AsciicastCreator

  def create(attributes, headers = {})
    attributes = AsciicastParams.new(attributes, headers).to_h
    asciicast = Asciicast.create!(attributes, without_protection: true)
    AsciicastWorker.perform_async(asciicast.id)

    asciicast
  end

end
