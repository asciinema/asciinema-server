class FakeTerminal

  def initialize
    @data = ''
  end

  def feed(data)
    @data << data
  end

  def screen
    { snapshot: @data, cursor: @data.size }
  end
end
