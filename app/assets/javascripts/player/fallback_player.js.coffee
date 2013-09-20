class AsciiIo.FallbackPlayer extends AsciiIo.AbstractPlayer

  createMovie: ->
    @movie = new AsciiIo.Movie @movieOptions()
