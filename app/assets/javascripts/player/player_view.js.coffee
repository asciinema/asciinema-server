class AsciiIo.PlayerView extends Backbone.View
  events:
    'click .start-prompt': 'onStartPromptClick'

  initialize: (options) ->
    @rendererView = new options.rendererClass(
      cols:  this.options.cols
      lines: this.options.lines
    )

    @hudView = new AsciiIo.HudView(cols:  this.options.cols)

    vt = new AsciiIo.VT(options.cols, options.lines, @rendererView)

    @movie = new AsciiIo.Movie(
      @model,
      vt,
      speed: options.speed,
      benchmark: options.benchmark
    )
    @movie.on 'movie-loaded', @onMovieLoaded, this
    @movie.load()

    @appendChildViews()

  appendChildViews: ->
    @$el.addClass('not-started')
    @$el.append(@rendererView.$el)
    @rendererView.afterInsertedToDom()
    @showLoadingIndicator()
    @$el.append(@hudView.$el)

  onStartPromptClick: ->
    @hideToggleOverlay()
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

    @movie.on 'movie-awake', (frame) =>
      @rendererView.restartCursorBlink()

    @movie.on 'movie-started', =>
      @$el.removeClass('not-started')

    @movie.on 'movie-finished', =>
      @rendererView.stopCursorBlink()

  showLoadingIndicator: ->
    @$el.append('<div class="loading">')

  hideLoadingIndicator: ->
    @$('.loading').remove()

  showToggleOverlay: ->
    @$el.append('<div class="start-prompt">')

  hideToggleOverlay: ->
    @$('.start-prompt').remove()
