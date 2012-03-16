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

  afterInsertedToDom: ->
    super()
    @initialRender()
    @fixSize()

  initialRender: ->
    brush = AsciiIo.Brush.normal()
    changes = {}

    i = 0
    while i < @lines
      changes[i] = [[' '.times(@cols), brush]]
      i += 1

    @render(changes, 0, 0)

  fixSize: ->
    width = @$el.width()
    height = @$el.height()
    @$el.css(width: width + 'px', height: height + 'px')

  render: (changes, cursorX, cursorY) ->
    @$el.find('.cursor').removeClass('cursor')
    super(changes, cursorX, cursorY)

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
    text.replace('&', '&amp;').replace('<', '&lt;')

  spanFromBrush: (brush) ->
    key = brush.hash()
    span = @cachedSpans[key]

    if not span
      span = ""

      if brush != AsciiIo.Brush.normal()
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
