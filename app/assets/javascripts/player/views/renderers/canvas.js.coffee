class Asciinema.Renderer.Canvas extends Asciinema.Renderer.Base
  tagName: 'canvas'
  className: 'terminal'

  events:
    'click': 'onClick'

  initialize: (options) ->
    super(options)
    @ctx = @el.getContext('2d')
    @cursorOn = true
    @cursorVisible = true

  fixTerminalElementSize: ->
    @$el.attr('width', @width())
    @$el.attr('height', @height())

    @setFont()

  setFont: ->
    size = @$el.css('font-size')
    family = @$el.css('font-family')
    @font = "#{size} #{family}"
    @ctx.font = @font
    @prevFont = @font
    @ctx.textBaseline = 'bottom'

  renderLine: (n, fragments, cursorX) ->
    left = 0
    width = @cols * @cellWidth
    top = n * @cellHeight
    cursorText = undefined
    rendered = 0

    for fragment in fragments
      [text, brush] = fragment

      brush = Asciinema.Brush.create brush if brush

      if cursorX isnt undefined and rendered <= cursorX < rendered + text.length
        @cursorBrush = brush
        @cursorText = text[cursorX - rendered]
        @cursorX = cursorX
        @cursorY = n

      @setBackgroundAttributes(brush)
      @ctx.fillRect left, top, text.length * @cellWidth, @cellHeight

      unless text.match(/^\s*$/)
        @setTextAttributes(brush)
        @ctx.fillText text, left, top + @cellHeight

      left += text.length * @cellWidth
      rendered += text.length

    if cursorX
      @renderCursor()

  setBackgroundAttributes: (brush) ->
    @ctx.fillStyle = Asciinema.colors[brush.bgColor()]

  setTextAttributes: (brush) ->
    @ctx.fillStyle = Asciinema.colors[brush.fgColor()]

    font = @font

    if brush.bright or brush.italic
      if brush.bright
        font = "bold #{font}"

      if brush.italic
        font = "italic #{font}"

    if font != @prevFont
      @ctx.font = font
      @prevFont = font

  renderCursor: ->
    return unless @cursorOn and @cursorText

    x = @cursorX * @cellWidth
    y = @cursorY * @cellHeight

    if @cursorVisible
      @ctx.fillStyle = Asciinema.colors[7]
      @ctx.fillRect x, y, @cellWidth, @cellHeight
      @ctx.fillStyle = Asciinema.colors[0]
      @ctx.fillText @cursorText, x, y + @cellHeight
    else
      @ctx.fillStyle = Asciinema.colors[@cursorBrush.bgColor()]
      @ctx.fillRect x, y, @cellWidth, @cellHeight
      @ctx.fillStyle = Asciinema.colors[@cursorBrush.fgColor()]
      @ctx.fillText @cursorText, x, y + @cellHeight

  showCursor: (show) ->
    @cursorOn = show

  flipCursor: ->
    @cursorVisible = !@cursorVisible
    @renderCursor()

  resetCursorState: ->
    @cursorVisible = true
    @renderCursor()
