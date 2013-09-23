class AsciiIo.Brush
  @default_fg = 7
  @default_bg = 0

  @cache: {}

  @clearCache: ->
    @cache = {}

  @default: ->
    @_default ||= @create()

  @hash: (brush) ->
    "#{brush.fg}_#{brush.bg}_#{brush.blink}_#{brush.bold}_#{brush.underline}_#{brush.inverse}"

  @create: (options = {}) ->
    key = @hash options
    brush = @cache[key]

    if not brush
      brush = new AsciiIo.Brush(options)
      @cache[key] = brush

    brush

  constructor: (options = {}) ->
    @fg        = undefined
    @bg        = undefined
    @blink     = false
    @bold      = false
    @underline = false
    @inverse   = false

    for name, value of options
      this[name] = value

  hash: ->
    AsciiIo.Brush.hash this

  attributes: ->
    fg       : @fg
    bg       : @bg
    blink    : @blink
    bold     : @bold
    underline: @underline
    inverse  : @inverse

  fgColor: ->
    if @inverse
      color = @calculateBgColor()
      if color != undefined
        color
      else
        AsciiIo.Brush.default_bg
    else
      @calculateFgColor()

  bgColor: ->
    if @inverse
      color = @calculateFgColor()
      if color != undefined
        color
      else
        AsciiIo.Brush.default_fg
    else
      @calculateBgColor()

  calculateFgColor: ->
    color = @fg
    color += 8 if color != undefined && color < 8 && @bold
    color

  calculateBgColor: ->
    color = @bg
    color += 8 if color != undefined && color < 8 && @blink
    color

  hasDefaultFg: ->
    color = @fgColor()
    color is undefined || color == AsciiIo.Brush.default_fg

  hasDefaultBg: ->
    color = @bgColor()
    color is undefined || color == AsciiIo.Brush.default_bg
