class AsciiIo.SgrInterpreter

  parse: (numbers) ->
    changes = {}

    i = 0
    while i < numbers.length
      n = numbers[i]

      if n is 0
        changes.fg        = undefined
        changes.bg        = undefined
        changes.blink     = false
        changes.bright    = false
        changes.italic    = false
        changes.underline = false
        changes.reverse   = false
      else if n is 1
        changes.bright = true
      else if n is 3
        changes.italic = true
      else if n is 4
        changes.underline = true
      else if n is 5
        changes.blink = true
      else if n is 7
        changes.reverse = true
      else if n is 23
        changes.italic = false
      else if n is 24
        changes.underline = false
      else if n is 25
        changes.blink = false
      else if n is 27
        changes.reverse = false
      else if n >= 30 and n <= 37
        changes.fg = n - 30
      else if n is 38
        changes.fg = numbers[i + 2]
        i += 2
      else if n is 39
        changes.fg = undefined
      else if n >= 40 and n <= 47
        changes.bg = n - 40
      else if n is 48
        changes.bg = numbers[i + 2]
        i += 2
      else if n is 49
        changes.bg = undefined
      else if n >= 90 and n <= 97
        changes.fg = n - 90
      else if n >= 100 and n <= 107
        changes.bg = n - 100

      i++

    changes
