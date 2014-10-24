class AsciicastCreator

  def create(attributes, token, username)
    user = User.for_api_token!(token, username)
    attributes = attributes.merge(user: user)
    asciicast = Asciicast.create!(attributes)
    AsciicastWorker.perform_async(asciicast.id)

    asciicast
  end

end
