class AsciiIo.TerminalView extends Backbone.View
  tagName: 'pre'
  className: 'terminal'

  events:
    'click': 'onClick'

  initialize: (options) ->
    @cols = options.cols
    @lines = options.lines
    @cachedSpans = {}

    @createChildElements()
    @showCursor true
    @startCursorBlink()
    # this.updateScreen();
    # this.render();

  createChildElements: ->
    i = 0

    while i < @lines
      row = $("<span class=\"line\">")
      @$el.append row
      @$el.append "\n"
      i++

  onClick: ->
    @trigger('terminal-click')
    @hideToggleOverlay()

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

  showLoadingIndicator: ->
    @$el.append('<div class="loading">')

  hideLoadingIndicator: ->
    @$('.loading').remove()

  showToggleOverlay: ->
    @$el.append('<div class="start-prompt">')

  hideToggleOverlay: ->
    @$('.start-prompt').remove()

  renderLine: (n, data, cursorX) ->
    html = []
    prevBrush = undefined

    for i in [0...@cols]
      d = data[i]

      if d
        [char, brush] = d

        char = char.replace('&', '&amp;').replace('<', '&lt;')

        if brush != prevBrush or i is cursorX or i is (cursorX + 1)
          if prevBrush
            html.push '</span>'

          html.push @spanFromBrush(brush, i is cursorX)

          prevBrush = brush

        html.push char
      else
        html.push ' '

    html.push '</span>' if prevBrush

    @$el.find(".line:eq(" + n + ")")[0].innerHTML = '<span>' + html.join('') + '</span>'

  spanFromBrush: (brush, hasCursor) ->
    key = "#{brush.hash()}_#{hasCursor}"
    span = @cachedSpans[key]

    if not span
      span = ""

      if hasCursor or brush != AsciiIo.Brush.normal()
        span = "<span class=\""

        if brush.fg isnt undefined
          fg = brush.fg
          fg += 8 if fg < 8 and brush.bright
          span += " fg" + fg

        if brush.bg isnt undefined
          bg = brush.bg
          bg += 8 if bg < 8 and brush.blink
          span += " bg" + bg

        if brush.bright
          span += " bright"

        if brush.underline
          span += " underline"

        if brush.italic
          span += " italic"

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
