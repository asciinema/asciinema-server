class AsciiIo.Brush
  @cache: {}

  @clearCache: ->
    @cache = {}

  @hash: (brush) ->
    "#{brush.fg}_#{brush.bg}_#{brush.bright}_#{brush.underline}"

  @create: (options) ->
    options ||= {}

    key = @hash(options)
    brush = @cache[key]

    if not brush
      brush = new AsciiIo.Brush(options)
      @cache[key] = brush

    brush

  constructor: (options) ->
    @fg        = options.fg
    @bg        = options.bg
    @bright    = options.bright
    @underline = options.underline
