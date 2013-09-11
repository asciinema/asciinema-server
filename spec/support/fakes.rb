class FakeTerminal

  def initialize
    @data = ''
  end

  def feed(data)
    @data << data
  end

  def snapshot
    @data
  end

  def cursor
    @data.size
  end

end
