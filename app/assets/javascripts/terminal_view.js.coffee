class AsciiIo.TerminalView extends Backbone.View
  tagName: 'pre'
  className: 'terminal'

  initialize: (options) ->
    @cols = options.cols
    @lines = options.lines

    @createChildElements()
    @showCursor true

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
    @cursorY = @cursorX = 0
    @$el.find(".line").empty()

  render: ->
    for _, n of @dirtyLines
      @renderLine n

    # @dirtyLines = {}

  renderLine: (n) ->
    html = @getLine(n)

    if n is @cursorY
      html = html.slice(0, @cursorX).concat([ "<span class=\"cursor\">" + (html[@cursorX] or "") + "</span>" ], html.slice(@cursorX + 1) or [])

    @$el.find(".line:eq(" + n + ")").html html.join("")

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
