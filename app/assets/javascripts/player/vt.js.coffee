class AsciiIo.VT

  constructor: (cols, lines, @renderer) ->
    @data = ''
    @sb = new AsciiIo.ScreenBuffer(cols, lines)

    @fg = @bg = undefined
    @bright = false
    @underline = false

    @compilePatterns()

  noop: ->

  # handleC0ControlSet: (data) ->
  #   console.log 'handling C0'

  handlePrintableCharacters: (text) ->

  # handleC1ControlSet: (data) ->

  # handleControlSequence: (data) ->

  _C0_PATTERNS:
    # C0 set of 7-bit control characters
    "[\x00-\x1f]":
      # bell
      "\x07": (data) -> @sb.bell()

      # backspace
      "\x08": (data) -> @sb.backspace()

      # Move the cursor to the next tab stop
      "\x09": (data) ->

      "\x0a": (data) -> @sb.cursorDown 1

      "\x0d": (data) -> @sb.cr()

      "\x0e": (data) ->

      "\x0f": (data) ->

      # Reserved (?)
      "\x82": (data) ->

      # Cancel Character, ignore previous character
      "\x94": (data) ->

      # Escape sequence
      "\x1b": _.extend({}, @_C0_PATTERNS, {

        # Control sequence
        "\x1b\\[": @_CS_PATTERNS
      })

  _CS_PATTERNS:
    "sth": 1

  _PATTERNS: _.extend({}, @_C0_PATTERNS, {
    # Printable characters
    "([\x20-\x7e])+": @handlePrintableCharacters

    # "Delete", always and everywhere ignored
    "[\x7f\xff]": @noop

    # C1 control set
    "[\x80-\x9f]":

      # Control sequence
      "\x9b": @_CS_PATTERNS

    # G1 Displayable, 94 additional displayable characters
    "[\xa1-\xfe]": @handlePrintableCharacters

    # Always and everywhere a blank space
    "\xa0": -> @handlePrintableCharacters(' ')

  })

  PATTERNS:
    "\x00": (data) ->
    "\x07": (data) -> @bell()
    "\x08": (data) -> @sb.backspace()
    "\x09": (data) -> # Moves the cursor to the next tab stop
    "\x0a": (data) -> @sb.cursorDown 1
    "\x0d": (data) -> @sb.cr()
    "\x0e": (data) ->
    "\x0f": (data) ->
    "\x82": (data) -> # Reserved (?)
    "\x94": (data) -> # Cancel Character, ignore previous character

    # 20 - 7e
    "([\x20-\x7e]|\xe2..|[\xc2\xc4\xc5].)+": (data, match) ->
      @sb.print match[0]

    "\x1b\\(B": (data) -> # SCS (Set G0 Character SET)

    "\x1b\\[([0-9;]*)([\x40-\x7e])": (data, match) ->
      if match[1].length == 0
        @params = []
      else
        @params = _(match[1].split(';')).map (n) -> if n is '' then undefined else parseInt(n)

      @n = @params[0]
      @m = @params[1]
      @handleCSI match[2]

    # private standards
    "\x1b\\[\\?([\x30-\x3f]+)([hlsr])": (data, match) ->
      # h = Sets DEC/xterm specific mode (http://ttssh2.sourceforge.jp/manual/en/about/ctrlseq.html#decmode)
      # l = Resets mode (http://ttssh2.sourceforge.jp/manual/en/about/ctrlseq.html#mode)
      # 1001 + s = ?
      # 1001 + r = ?
      modes = match[1].split(";")
      action = match[2]
      mode = undefined

      for mode in modes
        if mode is "1"
          # 1 + h / l = cursor keys stuff
        else if mode is "7"
          # Enables/disables autowrap mode
        else if mode is "12"
          if action is "h"
            # blinking cursor
          else action is "l"
            # steady cursor
        else if mode is "25"
          if action is "h"
            @renderer.showCursor true
          else if action is "l"
            @renderer.showCursor false
        else if mode is "47"
          if action is "h"
            @sb.switchToAlternateBuffer()
          else if action is "l"
            @sb.switchToNormalBuffer()
        else if mode is "1000"
          # Enables/disables normal mouse tracking
        else if mode is "1001"
          # pbly sth with mouse/keys...
        else if mode is "1002"
          # 2002 + h / l = mouse tracking stuff
        else if mode is "1049"
          if action is "h"
            # Save cursor position, switch to alternate screen buffer, and clear screen.
            @sb.saveCursor()
            @sb.switchToAlternateBuffer()
            @sb.clear()
          else if action is "l"
            # Clear screen, switch to normal screen buffer, and restore cursor position.
            @sb.clear()
            @sb.switchToNormalBuffer()
            @sb.restoreCursor()
        else
          throw "unknown mode: " + mode + action

    "\x1b\x3d": (data) -> # DECKPAM - Set keypad to applications mode (ESCape instead of digits)

    "\x1b\x3e": (data) -> # DECKPNM - Set keypad to numeric mode (digits intead of ESCape seq)

    "\x1b\x5d[012]\x3b.*?\x07": (data, match) -> # OSC - Operating System Command (terminal title)

    "\x1b\\[>c": (data) -> # Secondary Device Attribute request (?)

    "\x1bP([^\\\\])*?\\\\": (data) -> # DCS, Device Control String

    "\x1bM": ->
      @sb.ri()

    "\x1b\x37": (data) -> # save cursor pos and char attrs
      @sb.saveCursor()

    "\x1b\x38": (data) -> # restore cursor pos and char attrs
      @sb.restoreCursor()

  handleCSI: (term) ->
    switch term
      when "@"
        @sb.reserveCharacters @n
      when "A"
        @sb.cursorUp @n or 1
      when "B"
        @sb.cursorDown @n or 1
      when "C"
        @sb.cursorForward @n or 1
      when "D"
        @sb.cursorBack @n or 1
      when "G"
        @sb.setCursorColumn @n
      when "H"
        @sb.setCursorPos @n or 1, @m or 1
      when "J"
        @sb.eraseData @n or 0
      when "K"
        @sb.eraseInLine @n or 0
      when "L"
        @sb.insertLines @n or 1
      when "M"
        @sb.deleteLines @n or 1
      when "d" # VPA - Vertical Position Absolute
        @sb.setCursorLine(@n)
      when "l" # l, Reset mode
        console.log "(TODO) reset: " + @n
      when "m"
        @handleSGR @params
      when "P" # DCH - Delete Character, from current position to end of field
        @sb.deleteCharacter @n or 1
      when "r" # Set top and bottom margins (scroll region on VT100)
      else
        throw "no handler for CSI term: " + term

  handleSGR: (numbers) ->
    numbers = [0] if numbers.length is 0

    i = 0
    while i < numbers.length
      n = numbers[i]

      if n is 0
        @fg = @bg = undefined
        @bright = false
        @underline = false
      else if n is 1
        @bright = true
      else if n is 4
        @underline = true
      else if n is 24
        @underline = false
      else if n >= 30 and n <= 37
        @fg = n - 30
      else if n is 38
        @fg = numbers[i + 2]
        i += 2
      else if n is 39
        @fg = undefined
      else if n >= 40 and n <= 47
        @bg = n - 40
      else if n is 48
        @bg = numbers[i + 2]
        i += 2
      else if n is 49
        @bg = undefined

      i++

    props = {}
    props.fg = @fg if @fg
    props.bg = @bg if @bg
    props.bright = true if @bright
    props.underline = true if @underline

    @sb.setBrush AsciiIo.Brush.create(props)

  bell: ->
    @renderer.visualBell()
    # @trigger('bell')

  compilePatterns: ->
    @COMPILED_PATTERNS = ([new RegExp("^" + re), f] for re, f of @PATTERNS)

  feed: (data) ->
    @data += data

    while @data.length > 0
      match = null

      for pattern in @COMPILED_PATTERNS
        match = pattern[0].exec(@data)

        if match
          handler = pattern[1]
          handler.call(this, @data, match)
          @data = @data.slice(match[0].length)
          break

      break unless match

    changes = @sb.changes()
    @renderer.render(changes, @sb.cursorX, @sb.cursorY)
    @sb.clearChanges()

    @data.length is 0
