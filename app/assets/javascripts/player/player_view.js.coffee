class AsciiIo.PlayerView extends Backbone.View
  events:
    'click .start-prompt': 'onStartPromptClick'

  initialize: (options) ->
    @prepareSelfView()
    @createRendererView()
    @createHudView()
    @fetchModel()
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

  fetchModel: ->
    @model.fetch success: => @onModelFetched()

  onModelFetched: ->
    data = @model.get 'escaped_stdout_data'
    data = atob data

    if typeof window.Worker == 'function'
      @unpackModelDataViaWorker data
    else
      @unpackModelDataHere data

  unpackModelDataViaWorker: (data) ->
    worker = new Worker(window.worker_unpack_path)

    worker.onmessage = (event) =>
      @model.set stdout_data: event.data
      @onModelReady()

    worker.postMessage data

  unpackModelDataHere: (data) ->
    @model.set stdout_data: ArchUtils.bz2.decode(data)
    @onModelReady()

  onModelReady: ->
    @hideLoadingIndicator()
    @hudView.setDuration @model.get('duration')
    @createMovie()
    @bindEvents()

    if @options.autoPlay
      @movie.play()
    else
      @showToggleOverlay()

  createMovie: ->
    @vt = new AsciiIo.VT(@options.cols, @options.lines)

    @movie = new AsciiIo.Movie(
      timing: @model.get 'stdout_timing_data'
      stdout_data: @model.get 'stdout_data'
      duration: @model.get 'duration'
      speed: @options.speed,
      benchmark: @options.benchmark
      cols: @options.cols
      lines: @options.lines
    )

  bindEvents: ->
    @movie.on 'reset', => @vt.reset()
    @movie.on 'finished', => @vt.stopCursorBlink()
    @movie.on 'wakeup', => @vt.restartCursorBlink()
    @movie.on 'paused', => @hudView.onPause()
    @movie.on 'resumed', => @hudView.onResume()
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

    @hudView.on 'play-click', => @movie.togglePlay()
    @hudView.on 'seek-click', (percent) => @movie.seek(percent)

  onStartPromptClick: ->
    @hideToggleOverlay()
    @movie.togglePlay()

  showLoadingIndicator: ->
    @$el.append('<div class="loading">')

  hideLoadingIndicator: ->
    @$('.loading').remove()

  showToggleOverlay: ->
    @$el.append('<div class="start-prompt">')

  hideToggleOverlay: ->
    @$('.start-prompt').remove()
