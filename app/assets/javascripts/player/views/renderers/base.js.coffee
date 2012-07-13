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

  render: (state) ->
    for n, fragments of state.changes
      c = if parseInt(n) is state.cursorY then state.cursorX else undefined
      @renderLine n, fragments || [], c

  renderLine: (n, data, cursorX) ->
    throw '#renderLine not implemented'

  afterInsertedToDom: ->
    sample = $('<span class="font-sample"><span class="line"><span>M</span></span></span>')
    @$el.parent().append(sample)
    @cellWidth = sample.width()
    span = sample.find('span span')
    @cellHeight = span.height() + span.css('padding-top') + span.css('padding-bottom')
    sample.remove()
    @fixTerminalElementSize()
    @fixPlayerContainerSize()

  renderSnapshot: (text) ->
    i = 0
    for line in text.split("\n")
      fragments = [[line, AsciiIo.Brush.normal()]]
      @renderLine i, fragments, undefined
      i++

  fixTerminalElementSize: ->

  fixPlayerContainerSize: ->
    @$el.parent('.player').css(width: @$el.outerWidth() + 'px')

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
