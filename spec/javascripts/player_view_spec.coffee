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
      player = new AsciiIo.PlayerView(element, cols, lines, data, timing)
      expect(element.find('.terminal').length).toBe(1)
      expect(element.find('.hud').length).toBe(1)

    it 'creates TerminalView instance passing proper DOM element', ->
      spyOn(AsciiIo, 'TerminalView')
      player = new AsciiIo.PlayerView(element, cols, lines, data, timing)
      expect(AsciiIo.TerminalView).toHaveBeenCalledWith(element.find('.terminal')[0], cols, lines)

    it 'creates HudView instance passing proper DOM element', ->
      spyOn(AsciiIo, 'HudView')
      player = new AsciiIo.PlayerView(element, cols, lines, data, timing)
      expect(AsciiIo.HudView).toHaveBeenCalledWith(element.find('.hud')[0])

    it 'creates Movie instance', ->
      spyOn(AsciiIo, 'Movie')
      player = new AsciiIo.PlayerView(element, cols, lines, data, timing)
      expect(AsciiIo.Movie).toHaveBeenCalledWith(data, timing)

  describe 'events', ->
    it 'toggles movie playback when terminal-click is fired on terminal', ->

    it 'toggles movie playback when hud-play-click is fired on hud', ->

    it 'seeks movie playback when hud-seek-click is fired on hud', ->

    it 'toggles fullscreen view when hud-fullscreen-click is fired on hud', ->

    it 'stops cursor blinking when movie-finished is fired on movie', ->

    # it '  when movie-frame is fired on movie', ->
