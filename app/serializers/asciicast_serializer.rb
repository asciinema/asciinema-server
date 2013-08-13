class AsciicastSerializer

  def initialize(asciicast)
    @asciicast = asciicast
  end

  def as_json(*)
    asciicast.as_json
  end

  private

  attr_reader :asciicast

end
