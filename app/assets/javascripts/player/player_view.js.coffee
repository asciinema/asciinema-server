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
    @rendererView = new @options.rendererClass(
      cols:  @options.cols
      lines: @options.lines
    )

    @$el.append(@rendererView.$el)
    @rendererView.afterInsertedToDom()
    @rendererView.renderSnapshot @options.snapshot

  createHudView: ->
    @hudView = new AsciiIo.HudView(cols: @options.cols)
    @$el.append(@hudView.$el)

  createMovie: ->
    @vt = new AsciiIo.VT(@options.cols, @options.lines)

    @movie = new AsciiIo.Movie(
      @model,
      speed: @options.speed,
      benchmark: @options.benchmark
      cols: @options.cols
      lines: @options.lines
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
    @movie.on 'reset', => @vt.reset()
    @movie.on 'finished', => @vt.stopCursorBlink()
    @movie.on 'wakeup', => @vt.restartCursorBlink()
    @movie.on 'playback-paused', => @hudView.onPause()
    @movie.on 'playback-resumed', => @hudView.onResume()
    @movie.on 'time', (time) => @hudView.updateTime(time)
    @movie.on 'started', => @$el.removeClass('not-started')

    @movie.on 'data', (data) =>
      @vt.feed data
      @rendererView.render @vt.state()
      @vt.clearChanges()

    @vt.on 'cursor:blink:restart', => @rendererView.restartCursorBlink()
    @vt.on 'cursor:blink:stop', => @rendererView.stopCursorBlink()
    @vt.on 'cursor:show', => @rendererView.showCursor true
    @vt.on 'cursor:hide', => @rendererView.showCursor false

    @hudView.on 'hud-play-click', => @movie.togglePlay()
    @hudView.on 'hud-seek-click', (percent) => @movie.seek(percent)

  showLoadingIndicator: ->
    @$el.append('<div class="loading">')

  hideLoadingIndicator: ->
    @$('.loading').remove()

  showToggleOverlay: ->
    @$el.append('<div class="start-prompt">')

  hideToggleOverlay: ->
    @$('.start-prompt').remove()
