describe AsciiIo.PlayerView, ->
  element = null
  cols = 2
  lines = 5
  data = ''
  timing = []

  beforeEach ->
    element = $('<div>')

  describe 'constructor', ->
    it 'creates needed DOM elements inside player element', ->
      player = new AsciiIo.PlayerView({
        el: element, cols: cols, lines: lines, data: data, timing: timing
      })

      expect(element.find('.terminal').length).toBe(1)
      expect(element.find('.hud').length).toBe(1)

    it 'creates TerminalView instance passing proper DOM element', ->
      spyOn(AsciiIo, 'TerminalView').andReturn({ on: -> 'foo' })

      player = new AsciiIo.PlayerView({
        el: element, cols: cols, lines: lines, data: data, timing: timing
      })

      expect(AsciiIo.TerminalView).toHaveBeenCalledWith({
        el: element.find('.terminal')[0], cols: cols, lines: lines
      })

    it 'creates HudView instance passing proper DOM element', ->
      spyOn(AsciiIo, 'HudView')

      player = new AsciiIo.PlayerView({
        el: element, cols: cols, lines: lines, data: data, timing: timing
      })

      expect(AsciiIo.HudView).toHaveBeenCalledWith({
        el: element.find('.hud')[0]
      })

    it 'creates Movie instance', ->
      spyOn(AsciiIo, 'Movie').andCallThrough()

      player = new AsciiIo.PlayerView({
        el: element, cols: cols, lines: lines, data: data, timing: timing
      })

      expect(AsciiIo.Movie).toHaveBeenCalledWith(data, timing)

  describe 'events', ->
    it 'toggles movie playback when terminal-click is fired on terminal', ->
      player = new AsciiIo.PlayerView({
        el: element, cols: cols, lines: lines, data: data, timing: timing
      })
      spyOn player.movie, 'togglePlay'

      player.terminal.trigger 'terminal-click'

      expect(player.movie.togglePlay).toHaveBeenCalled()

    it 'toggles movie playback when hud-play-click is fired on hud', ->

    it 'seeks movie playback when hud-seek-click is fired on hud', ->

    it 'toggles fullscreen view when hud-fullscreen-click is fired on hud', ->

    it 'stops cursor blinking when movie-finished is fired on movie', ->

    # it '  when movie-frame is fired on movie', ->
