class AsciiIo.PlayerView extends Backbone.View

  initialize: (options) ->
    @movie = new AsciiIo.Movie(options.data, options.timing)
    @screenBuffer = new AsciiIo.ScreenBuffer(options.cols, options.lines)
    @interpreter = new AsciiIo.AnsiInterpreter(@screenBuffer)

    @createChildViews()
    @bindEvents()

  createChildViews: ->
    @terminalView = new AsciiIo.TerminalView(
      cols:  this.options.cols
      lines: this.options.lines
    )
    @$el.append(@terminalView.$el)

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
      @interpreter.feed(frame)
      changes = @screenBuffer.changes()
      @terminalView.render(changes)
      @screenBuffer.clearChanges()

    @movie.on 'movie-finished', =>
      @terminalView.stopCursorBlink()

  play: ->
    @movie.play()
