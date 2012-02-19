class AsciiIo.TerminalView extends Backbone.View
  tagName: 'pre'
  className: 'terminal'

  initialize: (options) ->
    @cols = options.cols
    @lines = options.lines
    @cachedSpans = {}

    @createChildElements()
    @showCursor true
    @startCursorBlink()
    # this.updateScreen();
    # this.render();
    #
    # this.renderLine(0); // we only need 1 line
    # this.element.css({ width: this.element.width(), height: this.element.height() });

  createChildElements: ->
    i = 0

    while i < @lines
      row = $("<span class=\"line\">")
      @$el.append row
      @$el.append "\n"
      i++

  clearScreen: ->
    # this.lineData.length = 0;
    # @cursorY = @cursorX = 0
    @$el.find(".line").empty()

  render: (changes, cursorX, cursorY) ->
    @$el.find('.cursor').removeClass('cursor')

    for n, data of changes
      c = if parseInt(n) is cursorY then cursorX else undefined
      @renderLine n, data || [], c

  afterInsertedToDom: ->
    width = @$el.width()
    height = @$el.height()
    @$el.css(width: width + 'px', height: height + 'px')

  renderLine: (n, data, cursorX) ->
    html = ''
    prevBrush = undefined

    for i in [0...@cols]
      d = data[i]

      if d
        [char, brush] = d

        char = char.replace('&', '&amp;').replace('<', '&lt;')

        if brush != prevBrush or i is cursorX or i is (cursorX + 1)
          if prevBrush
            html += '</span>'

          html += @spanFromBrush(brush, i is cursorX)

          prevBrush = brush

        html += char
      else
        html += ' '

    html += '</span>' if prevBrush

    @$el.find(".line:eq(" + n + ")").html html

  spanFromBrush: (brush, hasCursor) ->
    key = "#{AsciiIo.Brush.hash(brush)}_#{hasCursor}"
    span = @cachedSpans[key]

    if not span
      span = ""

      if hasCursor or brush.fg isnt undefined or brush.bg isnt undefined or brush.bright or brush.underline
        span = "<span class=\""

        if brush.fg isnt undefined
          fg = brush.fg
          fg += 8 if fg < 8 and brush.bright
          span += " fg" + fg

        if brush.bright
          span += " bright"

        if brush.underline
          span += " underline"

        if brush.italic
          span += " italic"

        span += " bg" + brush.bg if brush.bg isnt undefined
        span += " cursor visible" if hasCursor
        span += "\">"

      @cachedSpans[key] = span

    span

  showCursor: (show) ->
    if show
      @$el.addClass "cursor-on"
    else
      @$el.removeClass "cursor-on"

  blinkCursor: ->
    cursor = @$el.find(".cursor")
    if cursor.hasClass("visible")
      cursor.removeClass "visible"
    else
      cursor.addClass "visible"

  resetCursorState: ->
    cursor = @$el.find(".cursor")
    cursor.addClass "visible"

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
