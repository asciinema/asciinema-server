describe 'AsciiIo.Brush', ->

  describe '.clearCache', ->

    it 'resets cache hash', ->
      AsciiIo.Brush.create()
      expect(_(AsciiIo.Brush.cache).keys().length > 0).toBeTruthy()
      AsciiIo.Brush.clearCache()
      expect(_(AsciiIo.Brush.cache).keys().length).toEqual(0)

  describe '.create', ->

    beforeEach ->
      AsciiIo.Brush.clearCache()

    it 'returns new brush instance if not cached', ->
      brush = AsciiIo.Brush.create({ fg: 1})
      expect(brush instanceof AsciiIo.Brush).toBeTruthy()

    it 'returns existing brush instance if cached', ->
      brush = AsciiIo.Brush.create({ fg: 1})
      otherBrush = AsciiIo.Brush.create({ fg: 1, bg: 100 })
      anotherBrush = AsciiIo.Brush.create({ fg: 1})

      expect(_(AsciiIo.Brush.cache).keys().length).toEqual(2)
      expect(brush is anotherBrush).toBeTruthy()
