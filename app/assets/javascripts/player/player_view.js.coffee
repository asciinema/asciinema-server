class AsciiIo.PlayerView extends Backbone.View

  initialize: (options) ->
    @movie = new AsciiIo.Movie(@model)
    @movie.load()

    @terminalView = new AsciiIo.TerminalView(
      cols:  this.options.cols
      lines: this.options.lines
    )

    @vt = new AsciiIo.VT(options.cols, options.lines, @terminalView)

    @createChildViews()
    @bindEvents()

  createChildViews: ->
    @$el.append(@terminalView.$el)
    @terminalView.afterInsertedToDom()

    @hudView = new AsciiIo.HudView()
    @$el.append(@hudView.$el)

  bindEvents: ->
    @terminalView.on 'terminal-click', =>
      @movie.togglePlay()

    @hudView.on 'hud-play-click', =>
      @movie.togglePlay()

    @hudView.on 'hud-seek-click', (percent) =>
      @movie.seek(percent)

    @movie.on 'movie-frame', (frame) =>
      @vt.feed(frame)

    @movie.on 'movie-awake', (frame) =>
      @terminalView.restartCursorBlink()

    @movie.on 'movie-finished', =>
      @terminalView.stopCursorBlink()

  play: ->
    if @movie.isLoaded()
      @movie.play()
