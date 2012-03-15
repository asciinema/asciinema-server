class AsciiIo.PlayerView extends Backbone.View

  initialize: (options) ->
    @movie = new AsciiIo.Movie(@model)
    @movie.on 'movie-loaded', @onMovieLoaded, this
    @movie.load()

    @rendererView = new options.rendererClass(
      cols:  this.options.cols
      lines: this.options.lines
    )

    @vt = new AsciiIo.VT(options.cols, options.lines, @rendererView)

    @createChildViews()

  createChildViews: ->
    @$el.append(@rendererView.$el)
    @rendererView.afterInsertedToDom()
    @rendererView.showLoadingIndicator()

    @hudView = new AsciiIo.HudView()
    @$el.append(@hudView.$el)

  onMovieLoaded: (asciicast) ->
    @rendererView.hideLoadingIndicator()
    @hudView.setDuration(asciicast.get('duration'))

    @bindEvents()

    if @options.autoPlay
      @movie.play()
    else
      @rendererView.showToggleOverlay()

  bindEvents: ->
    @rendererView.on 'terminal-click', =>
      @movie.togglePlay()

    @hudView.on 'hud-play-click', =>
      @movie.togglePlay()

    @hudView.on 'hud-seek-click', (percent) =>
      @movie.seek(percent)

    @movie.on 'movie-playback-paused', =>
      @hudView.onPause()

    @movie.on 'movie-playback-resumed', =>
      @hudView.onResume()

    @movie.on 'movie-time', (time) =>
      @hudView.updateTime(time)

    @movie.on 'movie-frame', (frame) =>
      @vt.feed(frame)

    @movie.on 'movie-awake', (frame) =>
      @rendererView.restartCursorBlink()

    @movie.on 'movie-finished', =>
      @rendererView.stopCursorBlink()
      @hudView.setProgress(100)
