class AsciiIo.PlayerView extends Backbone.View
  events:
    'click .start-prompt': 'onStartPromptClick'

  initialize: (options) ->
    @createMainWorker()
    @createRendererView()
    @showLoadingIndicator()
    @createHudView() if options.hud
    @fetchModel()

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
    @$el.append @hudView.$el

  fetchModel: ->
    @model.fetch success: => @onModelFetched()

  onModelFetched: ->
    data = atob @model.get('escaped_stdout_data')
    worker = new Worker(window.unpackWorkerPath)

    worker.onmessage = (event) =>
      @model.set stdout_data: event.data
      @onModelReady()

    worker.postMessage data

  onModelReady: ->
    @hideLoadingIndicator()
    @hudView.setDuration @model.get('duration') if @options.hud
    @setupMainWorker()
    @bindEvents()

    if @options.autoPlay
      @movie.call 'play'
    else
      @showToggleOverlay()

  createMainWorker: ->
    @workerProxy = new AsciiIo.WorkerProxy(window.mainWorkerPath)

  setupMainWorker: ->
    @workerProxy.init
      timing: @model.get 'stdout_timing_data'
      stdout_data: @model.get 'stdout_data'
      duration: @model.get 'duration'
      speed: @options.speed
      benchmark: @options.benchmark
      cols: @options.cols
      lines: @options.lines

    @movie = @workerProxy.getObjectProxy 'movie'
    @vt = @workerProxy.getObjectProxy 'vt'

  bindEvents: ->
    @movie.on 'started', => @$el.addClass 'playing'
    @movie.on 'finished', => @$el.removeClass 'playing'

    @movie.on 'paused', =>
      @$el.addClass 'paused'
      @$el.removeClass 'playing'
      @hudView.onPause() if @options.hud

    @movie.on 'resumed', =>
      @$el.addClass 'playing'
      @$el.removeClass 'paused'
      @hudView.onResume() if @options.hud

    if @options.hud
      @movie.on 'time', (time) => @hudView.updateTime(time)

    @movie.on 'render', (state) => @rendererView.render state

    @vt.on 'cursor:blink:restart', => @rendererView.restartCursorBlink()
    @vt.on 'cursor:blink:stop', => @rendererView.stopCursorBlink()
    @vt.on 'cursor:show', => @rendererView.showCursor true
    @vt.on 'cursor:hide', => @rendererView.showCursor false

<<<<<<< HEAD
    if @options.hud
      @hudView.on 'play-click', => @movie.call 'togglePlay'
      @hudView.on 'seek-click', (percent) => @movie.call 'seek', percent

    if @options.benchmark
      @movie.on 'started', =>
        @startedAt = (new Date).getTime()

      @movie.on 'finished', =>
        now = (new Date).getTime()
        console.log "finished in #{(now - @startedAt) / 1000.0}s"

  onStartPromptClick: ->
    @hideToggleOverlay()
    @movie.call 'togglePlay'

  showLoadingIndicator: ->
    @$el.append('<div class="loading">')

  hideLoadingIndicator: ->
    @$('.loading').remove()

  showToggleOverlay: ->
    @$el.append('<div class="start-prompt"><div class="play-button"><div class="arrow">►</div></div></div>')

  hideToggleOverlay: ->
    @$('.start-prompt').remove()
