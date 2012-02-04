class AsciiIo.PlayerView

  constructor: (@element, cols, lines, data, timing) ->
    terminalElement = $('<pre class="terminal">')
    hudElement = $('<div class="hud">')

    @element.append(terminalElement)
    @element.append(hudElement)

    # @interpreter ?
    @terminal = new AsciiIo.TerminalView(terminalElement[0], cols, lines)
    @hud = new AsciiIo.HudView(hudElement[0])
    @movie = new AsciiIo.Movie(data, timing)
