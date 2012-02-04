class AsciiIo.PlayerView extends Backbone.View
  initialize: (options) ->
    @element = @$el

    terminalElement = $('<pre class="terminal">')
    hudElement = $('<div class="hud">')

    @element.append(terminalElement)
    @element.append(hudElement)

    # @interpreter ?
    @terminal = new AsciiIo.TerminalView({
      el: terminalElement[0], cols: options.cols, lines: options.lines
    })
    @hud = new AsciiIo.HudView({ el: hudElement[0] })
    @movie = new AsciiIo.Movie(options.data, options.timing)

    @terminal.on 'terminal-click', =>
      @movie.togglePlay()
