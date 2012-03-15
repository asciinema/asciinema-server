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
    # @$el.css(width: width + 'px', height: height + 'px')
    # @ctx.scale(1, 1)

  setFont: ->
    size = @$el.css('font-size')
    console.log size
    family = @$el.css('font-family')
    console.log family
    @font = "#{size} #{family}"
    @ctx.font = @font
    @prevFont = @font
    @ctx.textBaseline = 'bottom'

  renderLine: (n, data, cursorX) ->
    left = 0
    width = @cols * @cellWidth
    top = n * @cellHeight

    for i in [0...@cols]
      d = data[i]

      if d
        [char, brush] = d

        @setBackgroundAttributes(brush)
        @ctx.fillRect left + i * @cellWidth, top, @cellWidth, @cellHeight

        if char != ' '
          @setTextAttributes(brush)
          @ctx.fillText char, i * @cellWidth, top + @cellHeight

  setBackgroundAttributes: (brush) ->
    if brush.bg isnt undefined
      bg = brush.bg
      bg += 8 if bg < 8 and brush.blink
    else
      bg = 0

    @ctx.fillStyle = AsciiIo.colors[bg]

  setTextAttributes: (brush) ->
    if brush.fg isnt undefined
      fg = brush.fg
      fg += 8 if fg < 8 and brush.bright
    else
      fg = 7

    @ctx.fillStyle = AsciiIo.colors[fg]

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
