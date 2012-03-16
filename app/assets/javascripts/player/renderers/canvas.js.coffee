class AsciiIo.Renderer.Canvas extends AsciiIo.Renderer.Base
  tagName: 'canvas'
  className: 'terminal'

  events:
    'click': 'onClick'

  initialize: (options) ->
    super(options)
    @ctx = @el.getContext('2d')
    @cellWidth = 7
    @cellHeight = 14

  afterInsertedToDom: ->
    width = @cols * @cellWidth
    height = @lines * @cellHeight
    @$el.attr('width', width)
    @$el.attr('height', height)
    @setFont()

  setFont: ->
    size = @$el.css('font-size')
    # console.log size
    family = @$el.css('font-family')
    # console.log family
    @font = "#{size} #{family}"
    @ctx.font = @font
    @prevFont = @font
    @ctx.textBaseline = 'bottom'

  renderLine: (n, fragments, cursorX) ->
    left = 0
    width = @cols * @cellWidth
    top = n * @cellHeight

    for fragment in fragments
      [text, brush] = fragment

      @setBackgroundAttributes(brush)
      @ctx.fillRect left, top, text.length * @cellWidth, @cellHeight

      # if char != ' '
      @setTextAttributes(brush)
      @ctx.fillText text, left, top + @cellHeight

      left += text.length * @cellWidth

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
