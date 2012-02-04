describe AsciiIo.Movie, ->

  describe '#play', ->
    it 'calls nextFrame', ->
      movie = new AsciiIo.Movie('', [])
      spyOn movie, 'nextFrame'
      movie.play()
      expect(movie.nextFrame).toHaveBeenCalled()

  describe '#pause', ->

  describe '#toggle', ->

  describe '#seek', ->

  describe '#nextFrame', ->
    describe 'when playing', ->
      it 'triggers movie-frame event', ->

    describe 'when finished', ->
      it 'triggers movie-finished event', ->
