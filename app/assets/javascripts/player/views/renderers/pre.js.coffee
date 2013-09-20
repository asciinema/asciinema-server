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
    @$el.css(width: @width() + 'px', height: @height() + 'px')

  render: ->
    if @dirty
      @$el.find('.cursor').removeClass('cursor')

    super

  renderLine: (n, fragments, cursorX) ->
    html = []
    rendered = 0

    for fragment in fragments
      [text, brush] = fragment

      html.push @spanFromBrush(brush)
      html.push @escape(text)
      html.push '</span>'

      rendered += text.length

    @$el.find(".line:eq(" + n + ")")[0].innerHTML = '<span>' + html.join('') + '</span>'

  escape: (text) ->
    text.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')

  spanFromBrush: (brush) ->
    brush = AsciiIo.Brush.create brush

    key = brush.hash()
    span = @cachedSpans[key]

    if not span
      span = ""

      if brush != AsciiIo.Brush.default()
        span = "<span class=\""

        unless brush.hasDefaultFg()
          span += " fg" + brush.fgColor()

        unless brush.hasDefaultBg()
          span += " bg" + brush.bgColor()

        if brush.bold
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
