class AsciicastCreator

  def create(attributes, user)
    asciicast = Asciicast.create!(attributes.merge(user: user))
    AsciicastWorker.perform_async(asciicast.id)

    asciicast
  end

end
