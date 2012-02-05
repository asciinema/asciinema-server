class AsciiIo.Brush
  @cache: {}

  @clearCache: ->
    @cache = {}

  @create: (options) ->
    options ||= {}

    key = "#{options.fg}_#{options.bg}_#{options.bright}_#{options.underline}"
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
