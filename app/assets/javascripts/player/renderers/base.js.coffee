class AsciiIo.Renderer.Base extends Backbone.View
  events:
    'click': 'onClick'

  initialize: (options) ->
    @cols = options.cols
    @lines = options.lines
    @showCursor true
    @startCursorBlink()

  onClick: ->
    @trigger('terminal-click')
    @hideToggleOverlay()

  render: (changes, cursorX, cursorY) ->
    for n, data of changes
      c = if parseInt(n) is cursorY then cursorX else undefined
      @renderLine n, data || [], c

  renderLine: (n, data, cursorX) ->
    throw '#renderLine not implemented'

  afterInsertedToDom: ->

  showLoadingIndicator: ->
    @$el.append('<div class="loading">')

  hideLoadingIndicator: ->
    @$('.loading').remove()

  showToggleOverlay: ->
    @$el.append('<div class="start-prompt">')

  hideToggleOverlay: ->
    @$('.start-prompt').remove()

  showCursor: (show) ->
    throw '#showCursor not implemented'

  blinkCursor: ->
    throw '#blinkCursor not implemented'

  resetCursorState: ->

  startCursorBlink: ->
    @cursorTimerId = setInterval(@blinkCursor.bind(this), 500)

  stopCursorBlink: ->
    if @cursorTimerId
      clearInterval @cursorTimerId
      @cursorTimerId = null

  restartCursorBlink: ->
    @stopCursorBlink()
    @resetCursorState()
    @startCursorBlink()

  visualBell: ->
