class AsciiIo.Renderer.Base extends Backbone.View
  events:
    'click': 'onClick'

  initialize: (options) ->
    @cols = options.cols
    @lines = options.lines
    @showCursor true
    @startCursorBlink()
    @clearState()
    requestAnimationFrame @render

  width: ->
    @cols * @cellWidth

  height: ->
    @lines * @cellHeight

  elementWidth: ->
    @$el.outerWidth()

  clearState: ->
    @state =
      changes: {}
      cursorX: undefined
      cursorY: undefined
      dirty: false

  onClick: ->
    @trigger('terminal-click')

  push: (state) ->
    _(@state.changes).extend state.changes
    @state.cursorX = state.cursorX
    @state.cursorY = state.cursorY
    @state.dirty = true

  render: =>
    requestAnimationFrame @render

    if @state.dirty
      for n, fragments of @state.changes
        c = if parseInt(n) is @state.cursorY then @state.cursorX else undefined
        @renderLine n, fragments || [], c

      @clearState()

  renderLine: (n, data, cursorX) ->
    throw '#renderLine not implemented'

  afterInsertedToDom: ->
    sample = $('<span class="font-sample"><span class="line"><span>M</span></span></span>')
    span = sample.find('span span')

    @$el.parent().append sample

    @cellWidth = sample.width()

    @cellHeight = span.height() +
                  parseInt(span.css('padding-top')) +
                  parseInt(span.css('padding-bottom'))

    sample.remove()
    @fixTerminalElementSize()
    @fixPlayerContainerSize()

  renderSnapshot: (snapshot) ->
    return unless snapshot

    i = 0
    for line in snapshot
      fragments = _(line).map (fragment) ->
        fragment[1].bright = fragment[1].bold
        [fragment[0], new AsciiIo.Brush(fragment[1])]
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
