class AsciiIo.Renderer.Canvas extends AsciiIo.Renderer.Base
  tagName: 'canvas'
  className: 'terminal'

  events:
    'click': 'onClick'

  initialize: (options) ->
    super(options)
    @ctx = @el.getContext('2d')

  afterInsertedToDom: ->
    sample = $('<span class="font-sample">M</span>')
    @$el.parent().append(sample)
    @cellWidth = sample.width()
    @cellHeight = sample.height()
    sample.remove()

    @$el.attr('width', @cols * @cellWidth)
    @$el.attr('height', @lines * @cellHeight)

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

      if cursorX isnt undefined and rendered <= cursorX < rendered + text.length
        cursorText = text[cursorX - rendered]

      @setBackgroundAttributes(brush)
      @ctx.fillRect left, top, text.length * @cellWidth, @cellHeight

      unless text.match(/^\s*$/)
        @setTextAttributes(brush)
        @ctx.fillText text, left, top + @cellHeight

      left += text.length * @cellWidth
      rendered += text.length

    if cursorX
      x = cursorX * @cellWidth
      @ctx.fillStyle = AsciiIo.colors[7]
      @ctx.fillRect x, top, @cellWidth, @cellHeight
      if cursorText
        @ctx.fillStyle = AsciiIo.colors[0]
        @ctx.fillText cursorText, x, top + @cellHeight

  setBackgroundAttributes: (brush) ->
    @ctx.fillStyle = AsciiIo.colors[brush.bgColor()]

  setTextAttributes: (brush) ->
    @ctx.fillStyle = AsciiIo.colors[brush.fgColor()]

    font = @font

    if brush.bright or brush.italic
      if brush.bright
        font = "bold #{font}"

      if brush.italic
        font = "italic #{font}"

    if font != @prevFont
      @ctx.font = font
      @prevFont = font

  showCursor: (show) ->
    # if show
    #   @$el.addClass "cursor-on"
    # else
    #   @$el.removeClass "cursor-on"

  blinkCursor: ->
    # cursor = @$el.find(".cursor")
    # if cursor.hasClass("visible")
    #   cursor.removeClass "visible"
    # else
    #   cursor.addClass "visible"

  resetCursorState: ->
    # cursor = @$el.find(".cursor")
    # cursor.addClass "visible"
