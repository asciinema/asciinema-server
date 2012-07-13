class AsciiIo.PlayerView extends Backbone.View
  events:
    'click .start-prompt': 'onStartPromptClick'

  initialize: (options) ->
    @createMainWorker()
    @prepareSelfView()
    @createRendererView()
    @showLoadingIndicator()
    @createHudView() if options.hud
    @fetchModel()

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
    @$el.append @hudView.$el

  fetchModel: ->
    @model.fetch success: => @onModelFetched()

  onModelFetched: ->
    data = atob @model.get('escaped_stdout_data')
    worker = new Worker(window.worker_unpack_path)

    worker.onmessage = (event) =>
      @model.set stdout_data: event.data
      @onModelReady()

    worker.postMessage data

    # worker = new Worker(window.worker_path)

    # worker.onmessage = (event) =>
    #   @model.set stdout_data: event.data
    #   @onModelReady()
    #   # console.log event.data

    # worker.postMessage
    #   cmd: 'fetch'
    #   data: data

    # data = atob data

    # if typeof window.Worker == 'function'
    #   @unpackModelDataViaWorker data
    # else
    #   @unpackModelDataHere data

  # unpackModelDataViaWorker: (data) ->
  #   worker = new Worker(window.worker_unpack_path)

  #   worker.onmessage = (event) =>
  #     @model.set stdout_data: event.data
  #     @onModelReady()

  #   worker.postMessage data

  # unpackModelDataHere: (data) ->
  #   @model.set stdout_data: ArchUtils.bz2.decode(data)
  #   @onModelReady()

  onModelReady: ->
    @hideLoadingIndicator()
    @hudView.setDuration @model.get('duration') if @options.hud
    @setupMainWorker()
    @bindEvents()

    if @options.autoPlay
      @movie.play()
    else
      @showToggleOverlay()

  createMainWorker: ->
    @worker = new Worker(window.worker_path)

  setupMainWorker: ->
    @worker.postMessage
      cmd: 'init'
      timing: @model.get 'stdout_timing_data'
      stdout_data: @model.get 'stdout_data'
      duration: @model.get 'duration'
      speed: @options.speed
      benchmark: @options.benchmark
      cols: @options.cols
      lines: @options.lines

    @vt = new AsciiIo.VTWorkerProxy @worker, 'vt'
    @movie = new AsciiIo.MovieWorkerProxy @worker, 'movie'

  bindEvents: ->
    if @options.hud
      @movie.on 'paused', => @hudView.onPause()
      @movie.on 'resumed', => @hudView.onResume()
      @movie.on 'time', (time) => @hudView.updateTime(time)

    @movie.on 'started', => @$el.removeClass('not-started')
    @movie.on 'render', (state) => @rendererView.render state

    @vt.on 'cursor:blink:restart', => @rendererView.restartCursorBlink()
    @vt.on 'cursor:blink:stop', => @rendererView.stopCursorBlink()
    @vt.on 'cursor:show', => @rendererView.showCursor true
    @vt.on 'cursor:hide', => @rendererView.showCursor false

    if @options.hud
      @hudView.on 'play-click', => @movie.togglePlay()
      @hudView.on 'seek-click', (percent) => @movie.seek(percent)

    if @options.benchmark
      @movie.on 'started', =>
        @startedAt = (new Date).getTime()

      @movie.on 'finished', =>
        now = (new Date).getTime()
        console.log "finished in #{(now - @startedAt) / 1000.0}s"

  onStartPromptClick: ->
    @hideToggleOverlay()
    @movie.togglePlay()

  showLoadingIndicator: ->
    @$el.append('<div class="loading">')

  hideLoadingIndicator: ->
    @$('.loading').remove()

  showToggleOverlay: ->
    @$el.append('<div class="start-prompt"><div class="play-button"><div class="arrow">►</div></div></div>')

  hideToggleOverlay: ->
    @$('.start-prompt').remove()
