class AsciiIo.TerminalView extends Backbone.View
  tagName: 'pre'
  className: 'terminal'

  initialize: (options) ->
    @cols = options.cols
    @lines = options.lines

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

  renderLine: (n, data, cursorX) ->
    html = []
    i = 0

    for d in data
      if d
        [char, brush] = d
        html[i] = @createSpan(char, brush, i is cursorX)
      else
        html[i] = ' '
      i++

    @$el.find(".line:eq(" + n + ")").html html.join("")

  createSpan: (char, brush, hasCursor) ->
    prefix = ""
    postfix = ""

    if hasCursor or brush.fg isnt undefined or brush.bg isnt undefined or brush.bright or brush.underline
      prefix = "<span class=\""
      brightOffset = (if brush.bright then 8 else 0)

      if brush.fg isnt undefined
        prefix += " fg" + (brush.fg + brightOffset)
      else if brush.bright
        prefix += " bright"

      if brush.underline
        prefix += " underline"

      prefix += " bg" + brush.bg if brush.bg isnt undefined
      prefix += " cursor" if hasCursor
      prefix += "\">"
      postfix = "</span>"

    prefix + char + postfix

  showCursor: (show) ->
    if show
      @$el.addClass "cursor-on"
    else
      @$el.removeClass "cursor-on"

  blinkCursor: ->
    cursor = @$el.find(".cursor")
    if cursor.hasClass("inverted")
      cursor.removeClass "inverted"
    else
      cursor.addClass "inverted"

  startCursorBlink: ->
    @cursorTimerId = setInterval(@blinkCursor.bind(this), 500)

  stopCursorBlink: ->
    if @cursorTimerId
      clearInterval @cursorTimerId
      @cursorTimerId = null

  restartCursorBlink: ->
    @stopCursorBlink()
    @startCursorBlink()

  visualBell: ->
