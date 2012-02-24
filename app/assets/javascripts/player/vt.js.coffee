class AsciiIo.VT

  constructor: (@cols, @lines, @renderer) ->
    @data = ''
    @resetTerminal()
    @render()
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
      "\x07": (data) -> @bell()

      # backspace
      "\x08": (data) -> @backspace()

      # Move the cursor to the next tab stop
      "\x09": (data) ->

      "\x0a": (data) -> @lineFeed()

      "\x0d": (data) -> @carriageReturn()

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
    "\x08": (data) -> @backspace()
    "\x09": (data) -> @buffer.goToNextHorizontalTabStop()
    "\x0a": (data) -> @lineFeed()
    "\x0b": (data) -> @verticalTab()
    "\x0c": (data) -> @formFeed()
    "\x0d": (data) -> @carriageReturn()
    "\x0e": (data) ->
    "\x0f": (data) ->
    "\x82": (data) -> # Reserved (?)
    "\x85": (data) -> @setHorizontalTabStop()
    "\x94": (data) -> # Cancel Character, ignore previous character

    # 20 - 7e
    "([\x20-\x7e]|\xe2..|[\xc2\xc4\xc5].)+": (data, match) ->
      @buffer.print match[0]

    "\x1b\\(B": (data) -> # SCS (Set G0 Character SET)

    "\x1b\\[([0-9;]*)([\x40-\x7e])": (data, match) ->
      if match[1].length == 0
        @params = []
      else
        @params = _(match[1].split(';')).map (n) -> if n is '' then undefined else parseInt(n)

      @n = @params[0]
      @m = @params[1]
      @handleCS match[2]

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
        else if mode is "5"
          # Reverse/normal video - ignoring
        else if mode is "7"
          # Enables/disables autowrap mode
        else if mode is "12"
          if action is "h"
            # blinking cursor
          else action is "l"
            # steady cursor
        else if mode is "25"
          if action is "h"
            @showCursor()
          else if action is "l"
            @hideCursor()
        else if mode is "47"
          if action is "h"
            @switchToAlternateBuffer()
          else if action is "l"
            @switchToNormalBuffer()
        else if mode is "1000"
          # Enables/disables normal mouse tracking
        else if mode is "1001"
          # pbly sth with mouse/keys...
        else if mode is "1002"
          # 2002 + h / l = mouse tracking stuff
        else if mode is "1049"
          if action is "h"
            # Save cursor position, switch to alternate screen buffer, and clear screen.
            @switchToAlternateBuffer()
            @clearScreen()
          else if action is "l"
            # Clear screen, switch to normal screen buffer, and restore cursor position.
            @clearScreen()
            @switchToNormalBuffer()
        else
          throw "unknown mode: " + mode + action

    "\x1b\x3d": (data) -> # DECKPAM - Set keypad to applications mode (ESCape instead of digits)

    "\x1b\x3e": (data) -> # DECKPNM - Set keypad to numeric mode (digits intead of ESCape seq)

    "\x1b\\\\": -> # String Terminator (VT125 exits graphics)

    "\x1b\x5d[012]\x3b.*?\x07": (data, match) -> # OSC - Operating System Command (terminal title)

    "\x1b\\[>c": (data) -> # Secondary Device Attribute request (?)

    "\x1bc": -> @resetTerminal()
    "\x1bP([^\\\\])*?\\\\": (data) -> # DCS, Device Control String
    "\x1bD": -> @index()
    "\x1bE": -> @newLine()
    "\x1bH": -> @setHorizontalTabStop()
    "\x1bM": -> @reverseIndex()
    "\x1bk": -> # NAPLPS lock-shift G1 to GR

    "\x1b7": (data) -> # save cursor pos and char attrs
      @saveTerminalState()

    "\x1b8": (data) -> # restore cursor pos and char attrs
      @restoreTerminalState()

  handleCS: (term) ->
    switch term
      when "@"
        @buffer.insertCharacters @n
      when "A"
        @buffer.priorRow @n
      when "B"
        @buffer.nextRow @n
      when "C"
        @buffer.nextColumn @n
      when "D"
        @buffer.priorColumn @n
      when "E"
        @buffer.nextRowFirstColumn @n
      when "F"
        @buffer.priorRowFirstColumn @n
      when "G"
        @buffer.goToColumn @n
      when "H"
        @buffer.goToRowAndColumn @n, @m
      when "I"
        @buffer.goToNextHorizontalTabStop @n
      when "J"
        if @n is 2
          @buffer.eraseScreen()
        else if @n is 1
          @buffer.eraseFromScreenStart()
        else
          @buffer.eraseToScreenEnd()
      when "K"
        if @n is 2
          @buffer.eraseRow()
        else if @n is 1
          @buffer.eraseFromRowStart()
        else
          @buffer.eraseToRowEnd()
      when "L"
        @buffer.insertLine @n or 1
      when "M"
        @buffer.deleteLine @n or 1
      when "P" # DCH - Delete Character, from current position to end of field
        @buffer.deleteCharacters @n or 1
      when "S"
        @buffer.scrollUp @n
      when "T"
        @buffer.scrollDown @n
      when "X"
        @buffer.eraseCharacters @n
      when "Z"
        @buffer.goToPriorHorizontalTabStop @n
      when "b"
        @buffer.repeatLastCharacter @n
      when "d" # VPA - Vertical Position Absolute
        @buffer.goToRow @n
      when "f"
        @buffer.goToRowAndColumn @n, @m
      when "g"
        if !@n or @n is 0
          @buffer.clearHorizontalTabStop()
        else if @n is 3
          @buffer.clearAllHorizontalTabStops()
      when "l" # l, Reset mode
        console.log "(TODO) reset: " + @n
      when "m"
        @handleSGR @params
      when "n"
        @reportRowAndColumn()
      when "r" # Set top and bottom margins (scroll region on VT100)
        @setScrollRegion @n or 0, @m or @lines - 1
      when "^"
        # reserved
        # Privacy Message (password verification), terminated by ST
        # TODO
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
        # TODO: reset blink (and others?)
      else if n is 1
        @bright = true
      else if n is 3
        @italic = true
      else if n is 4
        @underline = true
      else if n is 5
        @blink = true
      else if n is 23
        @italic = false
      else if n is 24
        @underline = false
      else if n is 25
        @blink = false
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
    props.fg = @fg if @fg isnt undefined
    props.bg = @bg if @bg isnt undefined
    props.bright = true if @bright
    props.underline = true if @underline
    props.italic = true if @italic
    props.blink = true if @blink

    @buffer.setBrush AsciiIo.Brush.create(props)

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

    @render()

    @data.length is 0

  render: ->
    @renderer.render(@buffer.changes(), @buffer.cursorX, @buffer.cursorY)
    @buffer.clearChanges()

  # ==== Screen buffer operations

  clearScreen: ->
    @buffer.clear()

  switchToNormalBuffer: ->
    @buffer = @normalBuffer
    @updateScreen()

  switchToAlternateBuffer: ->
    @alternateBuffer.setBrush(@normalBuffer.getBrush())
    @buffer = @alternateBuffer
    @updateScreen()

  updateScreen: ->
    @buffer.updateScreen()

  carriageReturn: ->
    @buffer.goToFirstColumn()

  backspace: ->
    @buffer.priorColumn()

  # === ANSI handlers

  # ------ Cursor control

  showCursor: ->
    @renderer.showCursor true

  hideCursor: ->
    @renderer.showCursor false

  # ----- Scroll control

  reverseIndex: ->
    @goToPriorRow()

  lineFeed: ->
    @buffer.goToNextRow()

  verticalTab: ->
    @goToNextRow()

  formFeed: ->
    @buffer.goToNextRow()

  index: ->
    @buffer.goToNextRow()

  newLine: ->
    @buffer.goToNextRowFirstColumn()


  # === Commands

  # ----- Scroll control

  setScrollRegion: (top, bottom) ->
    @scrollRegion.setTop(top - 1)
    @scrollRegion.setBottom(bottom - 1)

  setHorizontalTabStop: ->
    @tabStops.add(@cursorX)

  # ----- Terminal control

  resetTerminal: ->
    @scrollRegion = new AsciiIo.ScrollRegion(0, @lines - 1)
    @tabStops = new AsciiIo.TabStops(@cols)

    @normalBuffer = new AsciiIo.ScreenBuffer(@cols, @lines, @scrollRegion, @tabStops)
    @alternateBuffer = new AsciiIo.ScreenBuffer(@cols, @lines, @scrollRegion, @tabStops)
    @buffer = @normalBuffer

    @updateScreen()

  saveTerminalState: ->
    @saveCursor()
    @scrollRegion.save()
    @saveBrush()

  restoreTerminalState: ->
    @restoreBrush()
    @scrollRegion.restore()
    @restoreCursor()

  reportRowAndColumn: ->

# http://www.shaels.net/index.php/propterm/documents
