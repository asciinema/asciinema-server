class AsciiIo.Brush
  @cache: {}

  @clearCache: ->
    @cache = {}

  @default: ->
    @_default ||= @create()

  @hash: (brush) ->
    "#{brush.fg}_#{brush.bg}_#{brush.bright}_#{brush.underline}_#{brush.italic}_#{brush.blink}"

  @create: (options = {}) ->
    key = @hash options
    brush = @cache[key]

    if not brush
      brush = new AsciiIo.Brush(options)
      @cache[key] = brush

    brush

  constructor: (options = {}) ->
    @fg        = options.fg
    @bg        = options.bg
    @blink     = options.blink
    @bright    = options.bright
    @italic    = options.italic
    @underline = options.underline

  hash: ->
    AsciiIo.Brush.hash this

  attributes: ->
    fg       : @fg
    bg       : @bg
    blink    : @blink
    bright   : @bright
    italic   : @italic
    underline: @underline

  fgColor: ->
    color = @fg
    color = 7 if color is undefined
    color += 8 if color < 8 and @bright
    color

  bgColor: ->
    color = @bg
    color = 0 if color is undefined
    color += 8 if color < 8 and @blink
    color
