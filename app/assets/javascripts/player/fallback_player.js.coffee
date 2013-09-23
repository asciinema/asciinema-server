class Asciinema.FallbackPlayer extends Asciinema.AbstractPlayer

  createMovie: ->
    @movie = new Asciinema.Movie @movieOptions()
