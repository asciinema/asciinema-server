class AsciiIo.Renderer.Base extends Backbone.View
  events:
    'click': 'onClick'

  initialize: (options) ->
    @cols = options.cols
    @lines = options.lines
    @showCursor true
    @startCursorBlink()
    @clearChanges()
    @cursor = { x: undefined, y: undefined, visible: true }
    requestAnimationFrame @render

  width: ->
    @cols * @cellWidth

  height: ->
    @lines * @cellHeight

  elementWidth: ->
    @$el.outerWidth()

  clearChanges: ->
    @changes = {}
    @dirty = false

  onClick: ->
    @trigger('terminal-click')

  push: (changes) ->
    if changes.lines
      _(@changes).extend changes.lines
      @dirty = true

    if changes.cursor
      _(@cursor).extend changes.cursor

  render: =>
    requestAnimationFrame @render

    if @dirty
      for n, fragments of @changes
        c = if parseInt(n) is @cursor.y then @cursor.x else undefined
        @renderLine n, fragments || [], c

      @clearChanges()

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

  flipCursor: ->
    throw '#flipCursor not implemented'

  resetCursorState: ->

  startCursorBlink: ->
    @cursorTimerId = setInterval(@flipCursor.bind(this), 500)

  stopCursorBlink: ->
    if @cursorTimerId
      clearInterval @cursorTimerId
      @cursorTimerId = null

  restartCursorBlink: ->
    @stopCursorBlink()
    @resetCursorState()
    @startCursorBlink()

  visualBell: ->
