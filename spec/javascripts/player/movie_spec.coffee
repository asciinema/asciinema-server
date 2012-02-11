describe AsciiIo.Movie, ->
  movie = data = timing = null

  beforeEach ->
    movie = null
    data = ''
    timing = []

  describe '#play', ->
    it 'calls nextFrame', ->
      movie = new AsciiIo.Movie(data, timing)
      spyOn movie, 'nextFrame'
      movie.play()
      expect(movie.nextFrame).toHaveBeenCalled()

  describe '#pause', ->

  describe '#togglePlay', ->

  describe '#seek', ->

  describe '#nextFrame', ->

    describe 'when playing', ->
      beforeEach ->
        data = 'X'

      it 'triggers movie-frame event immediately if delay is < MIN_DELAY', ->
        timing = [[0.8 * AsciiIo.Movie::MIN_DELAY, 1]]
        movie = new AsciiIo.Movie(data, timing)
        obj = { callback: -> true }
        movie.on('movie-frame', (arg) -> obj.callback(arg))
        spyOn(obj, 'callback')

        movie.nextFrame()

        expect(obj.callback).toHaveBeenCalledWith('X')

      it 'triggers movie-frame event after <delay> if delay is > MIN_DELAY', ->
        timing = [[20 * AsciiIo.Movie::MIN_DELAY, 1]]
        movie = new AsciiIo.Movie(data, timing)
        obj = { callback: -> true }
        movie.on('movie-frame', (arg) -> obj.callback(arg))
        spyOn(obj, 'callback')

        nextFrameCallTime = (new Date).getTime()
        ret = movie.nextFrame()

        expect(ret).toBe(true)

        waitsFor(
          ->
            called =
              obj.callback.callCount == 1 and obj.callback.argsForCall[0][0] == data
            actualDelay = ((new Date).getTime() - nextFrameCallTime) / 1000 # seconds
            diff = actualDelay - (timing[0][0] * (1.0 / AsciiIo.Movie::SPEED))
            isProperDelay = diff < Math.abs(0.02)
            called and isProperDelay
          'movie-frame event not triggered in <delay> time'
          1000
        )

    describe 'when finished', ->
      beforeEach ->
        timing = []
        movie = new AsciiIo.Movie(data, timing)

      it 'triggers movie-finished event', ->
        obj = { callback: -> true }
        movie.on('movie-finished', -> obj.callback())
        spyOn(obj, 'callback')

        ret = movie.nextFrame()

        expect(ret).toBe(false)
        expect(obj.callback).toHaveBeenCalled()
