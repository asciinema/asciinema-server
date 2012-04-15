class AsciiIo.PlayerView extends Backbone.View
  events:
    'click .start-prompt': 'onStartPromptClick'

  initialize: (options) ->
    @movie = new AsciiIo.Movie(
      @model,
      speed: options.speed,
      benchmark: options.benchmark
    )
    @movie.on 'movie-loaded', @onMovieLoaded, this
    @movie.load()

    @rendererView = new options.rendererClass(
      cols:  this.options.cols
      lines: this.options.lines
    )

    @vt = new AsciiIo.VT(options.cols, options.lines, @rendererView)

    @createChildViews()

  createChildViews: ->
    @$el.addClass('not-started')
    @$el.append(@rendererView.$el)
    @rendererView.afterInsertedToDom()
    @showLoadingIndicator()

    @hudView = new AsciiIo.HudView(cols:  this.options.cols)
    @$el.append(@hudView.$el)

  onStartPromptClick: ->
    @hideToggleOverlay()
    @$el.removeClass('not-started')
    @movie.togglePlay()

  onMovieLoaded: (asciicast) ->
    @hideLoadingIndicator()
    @hudView.setDuration(asciicast.get('duration'))

    @bindEvents()

    if @options.autoPlay
      @movie.play()
    else
      @showToggleOverlay()

  bindEvents: ->
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

    @movie.on 'movie-reset', =>
      @vt.reset()

    @movie.on 'movie-frame', (frame) =>
      @vt.feed(frame)

    @movie.on 'movie-awake', (frame) =>
      @rendererView.restartCursorBlink()

    @movie.on 'movie-finished', =>
      @rendererView.stopCursorBlink()
      @hudView.setProgress(100)

  showLoadingIndicator: ->
    @$el.append('<div class="loading">')

  hideLoadingIndicator: ->
    @$('.loading').remove()

  showToggleOverlay: ->
    @$el.append('<div class="start-prompt">')

  hideToggleOverlay: ->
    @$('.start-prompt').remove()
