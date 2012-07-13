class AsciiIo.SgrInterpreter

  reset: ->
    @attrs =
      fg       : undefined
      bg       : undefined
      blink    : false
      bright   : false
      italic   : false
      underline: false

  buildBrush: (oldBrush, numbers) ->
    @attrs =
      fg       : oldBrush.fg
      bg       : oldBrush.bg
      blink    : oldBrush.blink
      bright   : oldBrush.bright
      italic   : oldBrush.italic
      underline: oldBrush.underline

    numbers = [0] if numbers.length is 0

    i = 0
    while i < numbers.length
      n = numbers[i]

      if n is 0
        @reset()
      else if n is 1
        @attrs.bright = true
      else if n is 3
        @attrs.italic = true
      else if n is 4
        @attrs.underline = true
      else if n is 5
        @attrs.blink = true
      else if n is 23
        @attrs.italic = false
      else if n is 24
        @attrs.underline = false
      else if n is 25
        @attrs.blink = false
      else if n >= 30 and n <= 37
        @attrs.fg = n - 30
      else if n is 38
        @attrs.fg = numbers[i + 2]
        i += 2
      else if n is 39
        @attrs.fg = undefined
      else if n >= 40 and n <= 47
        @attrs.bg = n - 40
      else if n is 48
        @attrs.bg = numbers[i + 2]
        i += 2
      else if n is 49
        @attrs.bg = undefined
      else if n >= 90 and n <= 97
        @attrs.fg = n - 90
      else if n >= 100 and n <= 107
        @attrs.bg = n - 100

      i++

    AsciiIo.Brush.create @attrs
