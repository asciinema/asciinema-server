class Asciinema.Renderer.Pre extends Asciinema.Renderer.Base
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
      @$el.find('.cursor').removeClass('cursor').removeClass('flipped')

    super

  renderLine: (n, fragments, cursorX) ->
    html = []
    rendered = 0

    for fragment in fragments
      [text, brush] = fragment

      if cursorX isnt undefined and rendered <= cursorX < rendered + text.length
        left = text.slice(0, cursorX - rendered)
        cursor = text[cursorX - rendered]
        right = text.slice(cursorX - rendered + 1)

        if left.length > 0
          html.push @spanFromBrush(brush)
          html.push @escape(left)
          html.push '</span>'

        html.push @spanFromBrush(brush, true)
        html.push @escape(cursor)
        html.push '</span>'

        if right.length > 0
          html.push @spanFromBrush(brush)
          html.push @escape(right)
          html.push '</span>'
      else
        html.push @spanFromBrush(brush)
        html.push @escape(text)
        html.push '</span>'

      rendered += text.length

    @$el.find(".line:eq(" + n + ")")[0].innerHTML = '<span>' + html.join('') + '</span>'

  escape: (text) ->
    text.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')

  spanFromBrush: (brush, isCursor) ->
    brush = Asciinema.Brush.create brush

    key = "#{brush.hash()}_#{isCursor}"
    span = @cachedSpans[key]

    if not span
      span = ""

      if brush != Asciinema.Brush.default() || isCursor
        if isCursor
          span = "<span data-fg=#{brush.fgColor()} data-bg=#{brush.bgColor()} class=\"cursor"
        else
          span = "<span class=\""

        unless brush.hasDefaultFg()
          span += " fg" + brush.fgColor()

        unless brush.hasDefaultBg()
          span += " bg" + brush.bgColor()

        if brush.bold
          span += " bright"

        if brush.underline
          span += " underline"

        span += "\">"

      @cachedSpans[key] = span

    span

  showCursor: (show) ->
    if show
      @$el.addClass "cursor-on"
    else
      @$el.removeClass "cursor-on"

  flipCursor: ->
    cursor = @$el.find '.cursor'

    if cursor.hasClass 'flipped'
      @switchCursorColors cursor, false
    else
      @switchCursorColors cursor, true

  resetCursorState: ->
    @switchCursorColors @$el.find('.cursor'), false

  switchCursorColors: (cursor, flipped) ->
    if flipped
      fg = cursor.data 'fg'
      bg = cursor.data 'bg'
      cursor.removeClass "fg#{fg}"
      cursor.removeClass "bg#{bg}"
      cursor.addClass "fg#{bg} bg#{fg} flipped"
    else
      fg = cursor.data 'fg'
      bg = cursor.data 'bg'
      cursor.removeClass "fg#{bg}"
      cursor.removeClass "bg#{fg}"
      cursor.removeClass 'flipped'
      cursor.addClass "fg#{fg} bg#{bg}"
