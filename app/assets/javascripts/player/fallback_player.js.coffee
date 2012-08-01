class AsciiIo.FallbackPlayer extends AsciiIo.AbstractPlayer

  createVT: ->
    @vt = new AsciiIo.VT @options.cols, @options.lines

  createMovie: ->
    @movie = new AsciiIo.Movie @movieOptions()

  onModelReady: ->
    super

  bindEvents: ->
    super

    @movie.on 'reset', => @vt.reset()

    @movie.on 'data', (data) =>
      @vt.feed data
      state = @vt.state()
      @vt.clearChanges()
      @movie.trigger 'render', state
