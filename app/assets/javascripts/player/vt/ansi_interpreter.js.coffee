class AsciiIo.AnsiInterpreter

  constructor: (@callback) ->
    @cb = @callback
    @sgrInterpreter = new AsciiIo.SgrInterpreter()

  parse: (data) ->
    while data.length > 0
      processed = @handleData data

      if processed is 0
        # console.log "no kurwa: #{@formattedData(@data)}"
        break

      data = data.slice processed

    data

  handleData: (data) ->
    if data.match(/^\x1b[\x00-\x1f]/)
      @handleControlCharacter(data[1])
      return 2

    else if match = data.match(/^(\x1b\x5d|\x9d).*?(\x1b\\|\x9c|\x07)/)
      # OSC seq
      return match[0].length

    else if match = data.match(/^(\x1b[PX_^]|[\x90\x98\x9e\x9f]).*?(\x1b\\|\x9c)/)
      # DCS/SOS/PM/APC seq
      return match[0].length

    else if match = data.match(/^(?:\x1b\x5b|\x9b)([\x30-\x3f]*?)[\x20-\x2f]*?[\x40-\x7e]/)
      # Control sequences
      @handleControlSequence(match[0], match[1], match)
      return match[0].length

    else if match = data.match(/^\x1b[\x20-\x2f]*?[\x30-\x3f]/)
      @handlePrivateEscSeq(match[0])
      return match[0].length

    else if match = data.match(/^\x1b[\x20-\x2f]*?[\x40-\x5a\x5c\x5e-\x7e]/)
                                              # excluding \x5b ([) and \x5d (])
                                              # they're both handled above
      @handleStandardEscSeq(match[0])
      return match[0].length

    else if data.match(/^\x1b\x7f/) # DELETE
      return 2

    else if data.match(/^[\x00-\x1a\x1c-\x1f]/) # excluding \x1b "ESC"
      @handleControlCharacter(data[0])
      return 1

    else if match = data.match(/^([\x20-\x7e]|[\xe2-\xe8]..|[\xc2-\xc5].|[\xa1-\xfe])+/)
      @handlePrintableCharacters(match[0])
      return match[0].length

    else if data[0] is "\x7f"
      # DELETE, always and everywhere ignored
      return 1

    else if data.match(/^[\x80-\x9f]/)
      @handleControlCharacter(data[0])
      return 1

    else if data[0] is "\xa0"
      # Same as SPACE (\x20)
      @handlePrintableCharacters(' ')
      return 1

    else if data[0] is "\xff"
      # Same as DELETE (\x7f)
      return 1

    else
      return 0

  handleControlCharacter: (char) ->
    action = switch char
      when "\x07"
        'bell'
      when "\x08"
        'backspace'
      when "\x09"
        'goToNextHorizontalTabStop'
      when "\x0a"
        'lineFeed'
      when "\x0b"
        'verticalTab'
      when "\x0c"
        'formFeed'
      when "\x0d"
        'carriageReturn'
      when "\x84"
        'index' # "ESC D"
      when "\x85"
        'newLine' # "ESC E"
      when "\x88"
        'setHorizontalTabStop' # "ESC H"
      when "\x8d"
        'reverseIndex' # "ESC M"

    @cb action if action

  handlePrintableCharacters: (text) ->
    @cb 'print', text

  handleStandardEscSeq: (data) ->
    last = data[data.length - 1]
    intermediate = data[data.length - 2]

    action = switch last
      when "A"
        if intermediate is '('
          'setUkCharset'
      when "B"
        if intermediate is '('
          'setUsCharset'
      when "D"
        'index'
      when "E"
        'newLine'
      when "H"
        'setHorizontalTabStop'
      when "M"
        'reverseIndex'
      when "c"
        'resetTerminal'

    @cb action if action

  handlePrivateEscSeq: (data) ->
    last = data[data.length - 1]
    intermediate = data[data.length - 2]

    action = switch last
      when "0"
        if intermediate is '('
          'setSpecialCharset'
      when "7"
        'saveTerminalState'
      when "8"
        'restoreTerminalState'

    @cb action if action

  handleControlSequence: (data, params, match) ->
    if params and params.match(/^[\x3c-\x3f]/)
      @handlePrivateControlSequence(data, params)
    else
      @handleStandardControlSequence(data, params)

  handleStandardControlSequence: (data, params) ->
    term = data[data.length - 1]

    numbers = @parseParams params
    n = numbers[0]
    m = numbers[1]

    switch term
      when "@"
        @cb 'reserveCharacters', n
      when "A"
        n = 1 if n is undefined
        @cb 'priorRow', n
      when "B"
        n = 1 if n is undefined
        @cb 'nextRow', n
      when "C"
        n = 1 if n is undefined
        @cb 'nextColumn', n
      when "D"
        n = 1 if n is undefined
        @cb 'priorColumn', n
      when "E"
        @cb 'nextRowFirstColumn', n
      when "F"
        @cb 'priorRowFirstColumn', n
      when "G"
        n = 1 if n is undefined
        @cb 'goToColumn', n
      when "H"
        n = 1 if n is undefined
        m = 1 if m is undefined
        @cb 'goToRowAndColumn', n, m
      when "I"
        @cb 'goToNextHorizontalTabStop', n
      when "J"
        if n is 2
          @cb 'eraseScreen'
        else if n is 1
          @cb 'eraseFromScreenStart'
        else
          @cb 'eraseToScreenEnd'
      when "K"
        if n is 2
          @cb 'eraseRow'
        else if n is 1
          @cb 'eraseFromRowStart'
        else
          @cb 'eraseToRowEnd'
      when "L"
        @cb 'insertLines', n or 1
      when "M"
        @cb 'deleteLines', n or 1
      when "P" # DCH - Delete Character, from current position to end of field
        @cb 'deleteCharacters', n or 1
      when "S"
        @cb 'scrollUp', n
      when "T"
        @cb 'scrollDown', n
      when "X"
        @cb 'eraseCharacters', n
      when "Z"
        @cb 'goToPriorHorizontalTabStop', n
      when "b"
        @cb 'repeatLastCharacter', n
      when "d" # VPA - Vertical Position Absolute
        @cb 'goToRow', n
      when "f"
        @cb 'goToRowAndColumn', n, m
      when "g"
        if !n or n is 0
          @cb 'clearHorizontalTabStop'
        else if n is 3
          @cb 'clearAllHorizontalTabStops'
      when "l" # l, Reset mode
        console.log "(TODO) reset: " + n
      when "m"
        @handleSGR numbers
      when "n"
        @cb 'reportRowAndColumn'
      when "r" # Set top and bottom margins (scroll region on VT100)
        if n is undefined
          n = 1
        if m is undefined
          m = @lines
        @cb 'setScrollRegion', n, m

  handlePrivateControlSequence: (data, params) ->
    action = data[data.length - 1]
    modes = @parseParams params

    for mode in modes
      if mode is 25
        if action is "h"
          @cb 'showCursor'
        else if action is "l"
          @cb 'hideCursor'
      else if mode is 47
        if action is "h"
          @cb 'switchToAlternateBuffer'
        else if action is "l"
          @cb 'switchToNormalBuffer'
      else if mode is 1049
        if action is "h"
          # Save cursor position, switch to alternate screen buffer, and clear screen.
          @cb 'switchToAlternateBuffer'
          @cb 'eraseScreen'
        else if action is "l"
          # Clear screen, switch to normal screen buffer, and restore cursor position.
          @cb 'eraseScreen'
          @cb 'switchToNormalBuffer'

  parseParams: (params) ->
    if params.length is 0
      numbers = []
    else
      numbers = _(params.replace(/[^0-9;]/, '').split(';')).map (n) ->
        if n is '' then undefined else parseInt(n, 10)

    numbers

  handleSGR: (numbers) ->
    numbers = [0] if numbers.length is 0
    changes = @sgrInterpreter.parse numbers
    @cb 'updateBrush', changes

  formattedData: (data) ->
    head = data.slice(0, 100)
    hex = ("0x#{c.charCodeAt(0).toString(16)}" for c in head)
    Utf8.decode(head) + " (" + hex.join() + ")"
