class AsciiIo.Renderer.Pre extends AsciiIo.Renderer.Base
  tagName: 'pre'
  className: 'terminal'

  initialize: (options) ->
    super(options)

    @cachedSpans = {}
    @createChildElements()

  createChildElements: ->
    i = 0

    while i < @lines
      row = $("<span class=\"line\">")
      @$el.append row
      @$el.append "\n"
      i++

  fixTerminalElementSize: ->
    width = @cols * @cellWidth
    height = @lines * @cellHeight

    @$el.css(width: width + 'px', height: height + 'px')

  render: ->
    if @state.dirty
      @$el.find('.cursor').removeClass('cursor')

    super

  renderLine: (n, fragments, cursorX) ->
    html = []
    rendered = 0

    for fragment in fragments
      [text, brush] = fragment

      if cursorX isnt undefined and rendered <= cursorX < rendered + text.length
        left = text.slice(0, cursorX - rendered)
        cursor =
          '<span class="cursor visible">' + text[cursorX - rendered] + '</span>'
        right = text.slice(cursorX - rendered + 1)

        t = @escape(left) + cursor + @escape(right)
      else
        t = @escape(text)

      html.push @spanFromBrush(brush)
      html.push t
      html.push '</span>'

      rendered += text.length

    @$el.find(".line:eq(" + n + ")")[0].innerHTML = '<span>' + html.join('') + '</span>'

  escape: (text) ->
    text.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')

  spanFromBrush: (brush) ->
    brush = new AsciiIo.Brush brush

    key = brush.hash()
    span = @cachedSpans[key]

    if not span
      span = ""

      if brush != AsciiIo.Brush.default()
        span = "<span class=\""

        if brush.fg isnt undefined
          span += " fg" + brush.fgColor()

        if brush.bg isnt undefined
          span += " bg" + brush.bgColor()

        if brush.bright
          span += " bright"

        if brush.underline
          span += " underline"

        if brush.italic
          span += " italic"

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

  # TODO: check if it's used
  clearScreen: ->
    # this.lineData.length = 0;
    # @cursorY = @cursorX = 0
    @$el.find(".line").empty()
