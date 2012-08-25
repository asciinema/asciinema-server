class AsciiIo.Brush
  @defaultAttrs =
    fg       : undefined
    bg       : undefined
    blink    : false
    bright   : false
    italic   : false
    underline: false

  @default: ->
    @_default ||= new AsciiIo.Brush()

  @hash: (brush) ->
    "#{brush.fg}_#{brush.bg}_#{brush.bright}_#{brush.underline}_#{brush.italic}_#{brush.blink}"

  constructor: (options = {}) ->
    _(this).extend AsciiIo.Brush.defaultAttrs, options

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
