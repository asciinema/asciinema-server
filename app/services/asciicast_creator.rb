class AsciicastCreator

  def create(attributes, headers = {})
    attributes = AsciicastParams.build(attributes, headers).attributes
    asciicast = Asciicast.create!(attributes, without_protection: true)
    AsciicastWorker.perform_async(asciicast.id)

    asciicast
  end

end
