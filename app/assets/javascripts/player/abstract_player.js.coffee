class AsciiIo.AbstractPlayer

  constructor: (@options) ->
    @model = @options.model
    @createView()
    @fetchModel()

  createView: ->
    @view = new AsciiIo.PlayerView
      el: @options.el
      model: @model
      cols: @options.cols
      lines: @options.lines
      hud: @options.hud
      rendererClass: @options.rendererClass
      snapshot: @options.snapshot
      containerWidth: @options.containerWidth

  createVT: ->
    throw 'not implemented'

  createMovie: ->
    throw 'not implemented'

  movieOptions: ->
    timing: @model.get 'stdout_timing_data'
    stdout_data: @model.get 'stdout_data'
    duration: @model.get 'duration'
    speed: @options.speed
    benchmark: @options.benchmark
    cols: @options.cols
    lines: @options.lines

  fetchModel: ->
    @model.fetch success: @onModelFetched

  onModelFetched: =>
    data = @model.get('escaped_stdout_data')
    unpacker = new AsciiIo.DataUnpacker
    unpacker.unpack data, @onModelDataUnpacked

  onModelDataUnpacked: (data) =>
    @model.set stdout_data: data
    @onModelReady()

  onModelReady: ->
    @createVT()
    @createMovie()
    @bindEvents()
    @view.onModelReady()

    if @options.autoPlay
      @movie.call 'play'
    else
      @view.showPlayOverlay()

  bindEvents: ->
    @view.on 'play-clicked', => @movie.call 'togglePlay'
    @view.on 'seek-clicked', (percent) => @movie.call 'seek', percent

    @vt.on 'cursor-visibility', (show) => @view.showCursor show

    @movie.on 'started', => @view.onStateChanged 'playing'
    @movie.on 'paused', => @view.onStateChanged 'paused'
    @movie.on 'finished', => @view.onStateChanged 'finished'
    @movie.on 'resumed', => @view.onStateChanged 'resumed'
    @movie.on 'wakeup', => @view.restartCursorBlink()
    @movie.on 'time', (time) => @view.updateTime time
    @movie.on 'render', (state) => @view.renderState state

    if @options.benchmark
      @movie.on 'started', => @startedAt = (new Date).getTime()

      @movie.on 'finished', =>
        now = (new Date).getTime()
        console.log "finished in #{(now - @startedAt) / 1000.0}s"
