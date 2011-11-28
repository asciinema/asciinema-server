class AsciiIo.AnsiInterpreter
  constructor: (terminal) ->
    @terminal = terminal
    @compilePatterns()

  PATTERNS:
    "\x07": (data) -> # bell
    "\x08": (data) -> @terminal.bs()
    "\x0a": (data) -> @terminal.cursorDown()
    "\x0d": (data) -> @terminal.cr()
    "\x0e": (data) ->
    "\x0f": (data) ->
    "\x82": (data) -> # Reserved (?)
    "\x94": (data) -> # Cancel Character, ignore previous character

    # 20 - 7e
    "([\x20-\x7e]|\xe2..|[\xc2\xc4\xc5].)+": (data, match) ->
      @terminal.print match[0]

    "\x1b\\(B": (data) -> # SCS (Set G0 Character SET)

    "\x1b\\[(?:[0-9]+)?(?:;[0-9]+)*([\x40-\x7e])": (data, match) ->
      @params = []
      re = /(\d+)/g
      m = undefined
      @params.push parseInt(m[1])  while m = re.exec(match[0])
      @n = @params[0]
      @m = @params[1]
      @handleCSI match[1]

    # private standards
    "\x1b\\[\\?([\x30-\x3f]+)([hlsr])": (data, match) ->
      # h = Sets DEC/xterm specific mode (http://ttssh2.sourceforge.jp/manual/en/about/ctrlseq.html#decmode)
      # l = Resets mode (http://ttssh2.sourceforge.jp/manual/en/about/ctrlseq.html#mode)
      # 1001 + s = ?
      # 1001 + r = ?
      modes = match[1].split(";")
      action = match[2]
      mode = undefined
      i = 0

      while i < modes.length
        mode = modes[i]
        if mode is "1049"
          if action is "h"
            # Save cursor position, switch to alternate screen buffer, and clear screen.
            @terminal.saveCursor()
            @terminal.switchToAlternateBuffer()
            @terminal.clearScreen()
          else if action is "l"
            # Clear screen, switch to normal screen buffer, and restore cursor position.
            @terminal.clearScreen()
            @terminal.switchToNormalBuffer()
            @terminal.restoreCursor()
        else if mode is "1000"
          # Enables/disables normal mouse tracking
        else if mode is "1001"
          # pbly sth with mouse/keys...
        else if mode is "1002"
          # 2002 + h / l = mouse tracking stuff
        else if mode is "1"
          # 1 + h / l = cursor keys stuff
        else if mode is "47"
          if action is "h"
            @terminal.switchToAlternateBuffer()
          else if action is "l"
            @terminal.switchToNormalBuffer()
        else if mode is "25"
          if action is "h"
            @terminal.showCursor true
          else if action is "l"
            @terminal.showCursor false
        else if mode is "12"
          if action is "h"
            # blinking cursor
          else action is "l"
            # steady cursor
        else
          throw "unknown mode: " + mode + action
        i++

    "\x1b\x3d": (data) -> # DECKPAM - Set keypad to applications mode (ESCape instead of digits)

    "\x1b\x3e": (data) -> # DECKPNM - Set keypad to numeric mode (digits intead of ESCape seq)

    "\x1b\\\x5d[012]\x3b(?:.)*?\x07": (data, match) -> # OSC - Operating System Command (terminal title)

    "\x1b\\[>c": (data) -> # Secondary Device Attribute request (?)

    "\x1bP([^\\\\])*?\\\\": (data) -> # DCS, Device Control String

    "\x1bM": ->
      @terminal.ri @n or 1

    "\x1b\x37": (data) -> # save cursor pos and char attrs
      @terminal.saveCursor()

    "\x1b\x38": (data) -> # restore cursor pos and char attrs
      @terminal.restoreCursor()

  handleCSI: (term) ->
    switch term
      when "@"
        @terminal.reserveCharacters @n
      when "A"
        @terminal.cursorUp @n or 1
      when "B"
        @terminal.cursorDown @n or 1
      when "C"
        @terminal.cursorForward @n or 1
      when "D"
        @terminal.cursorBack @n or 1
      when "H"
        @terminal.setCursorPos @n or 1, @m or 1
      when "J"
        @terminal.eraseData @n or 0
      when "K"
        @terminal.eraseInLine @n or 0
      when "L"
        @terminal.insertLines @cursorY, @n or 1
      when "l" # l, Reset mode
        console.log "(TODO) reset: " + @n
      when "m"
        @terminal.setSGR @params
      when "P" # DCH - Delete Character, from current position to end of field
        @terminal.deleteCharacter @n or 1
      when "r" # Set top and bottom margins (scroll region on VT100)
      else
        throw "no handler for CSI term: " + term

  compilePatterns: ->
    @COMPILED_PATTERNS = []
    regexp = undefined
    for re of @PATTERNS
      regexp = new RegExp("^" + re)
      @COMPILED_PATTERNS.push [ regexp, @PATTERNS[re] ]

  feed: (data) ->
    match = undefined
    handler = undefined
    while data.length > 0
      match = handler = null
      i = 0

      while i < @COMPILED_PATTERNS.length
        pattern = @COMPILED_PATTERNS[i]
        match = pattern[0].exec(data)
        if match
          handler = pattern[1]
          break
        i++
      if handler
        handler.call this, data, match
        data = data.slice(match[0].length)
      else
        return data
    ""
