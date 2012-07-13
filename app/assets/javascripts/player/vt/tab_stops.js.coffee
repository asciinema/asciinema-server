class AsciiIo.TabStops

  constructor: (@cols) ->
    @stops = (x for x in [0...@cols] when x % 8 is 0)

  add: (col) ->
    unless _(@stops).include(col)
      pos = _(@stops).sortedIndex(col)
      @stops.splice(pos, 0, col)

  next: (cursorX) ->
    for x in @stops
      if x > cursorX
        return x

    @cols

  prev: (cursorX) ->
    ret = 0

    for x in @stops
      if x > cursorX
        break

      ret = x

    ret

