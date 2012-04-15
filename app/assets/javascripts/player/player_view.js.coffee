class AsciiIo.PlayerView extends Backbone.View
  events:
    'click .start-prompt': 'onStartPromptClick'

  initialize: (options) ->
    @prepareSelfView()
    @createRendererView()
    @createHudView()
    @createMovie()
    @showLoadingIndicator()

  prepareSelfView: ->
    @$el.addClass('not-started')

  createRendererView: ->
    @rendererView = new this.options.rendererClass(
      cols:  this.options.cols
      lines: this.options.lines
    )

    @$el.append(@rendererView.$el)
    @rendererView.afterInsertedToDom()

  createHudView: ->
    @hudView = new AsciiIo.HudView(cols:  this.options.cols)
    @$el.append(@hudView.$el)

  createMovie: ->
    vt = new AsciiIo.VT(this.options.cols, this.options.lines, @rendererView)

    @movie = new AsciiIo.Movie(
      @model,
      vt,
      speed: this.options.speed,
      benchmark: this.options.benchmark
    )
    @movie.on 'movie-loaded', @onMovieLoaded, this
    @movie.load()

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

    @movie.on 'movie-started', =>
      @$el.removeClass('not-started')

  showLoadingIndicator: ->
    @$el.append('<div class="loading">')

  hideLoadingIndicator: ->
    @$('.loading').remove()

  showToggleOverlay: ->
    @$el.append('<div class="start-prompt">')

  hideToggleOverlay: ->
    @$('.start-prompt').remove()
