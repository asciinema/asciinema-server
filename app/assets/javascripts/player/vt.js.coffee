class AsciiIo.VT

  constructor: (@cols, @lines, @renderer) ->
    @cursorX = 0
    @cursorY = 0
    @topMargin = 0
    @bottomMargin = @lines - 1
    @normalBuffer = []
    @alternateBuffer = []
    @lineData = @normalBuffer
    @dirtyLines = {}
    @brush = AsciiIo.Brush.create({})
    @data = ''
    # @sb = new AsciiIo.ScreenBuffer(cols, lines)

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
      "\x07": (data) -> @bell()

      # backspace
      "\x08": (data) -> @backspace()

      # Move the cursor to the next tab stop
      "\x09": (data) ->

      "\x0a": (data) -> @lineFeed()

      "\x0d": (data) -> @cr()

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
    "\x09": (data) -> # Moves the cursor to the next tab stop
    "\x0a": (data) -> @lineFeed()
    "\x0d": (data) -> @cr()
    "\x0e": (data) ->
    "\x0f": (data) ->
    "\x82": (data) -> # Reserved (?)
    "\x94": (data) -> # Cancel Character, ignore previous character

    # 20 - 7e
    "([\x20-\x7e]|\xe2..|[\xc2\xc4\xc5].)+": (data, match) ->
      @print match[0]

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
            @saveCursor()
            @switchToAlternateBuffer()
            @clearScreen()
          else if action is "l"
            # Clear screen, switch to normal screen buffer, and restore cursor position.
            @clearScreen()
            @switchToNormalBuffer()
            @restoreCursor()
        else
          throw "unknown mode: " + mode + action

    "\x1b\x3d": (data) -> # DECKPAM - Set keypad to applications mode (ESCape instead of digits)

    "\x1b\x3e": (data) -> # DECKPNM - Set keypad to numeric mode (digits intead of ESCape seq)

    "\x1b\x5d[012]\x3b.*?\x07": (data, match) -> # OSC - Operating System Command (terminal title)

    "\x1b\\[>c": (data) -> # Secondary Device Attribute request (?)

    "\x1bP([^\\\\])*?\\\\": (data) -> # DCS, Device Control String

    "\x1bD": ->
      console.log 'ya yebie'

    "\x1bM": ->
      @reverseIndex()

    "\x1b\x37": (data) -> # save cursor pos and char attrs
      @saveCursor()

    "\x1b\x38": (data) -> # restore cursor pos and char attrs
      @restoreCursor()

  handleCSI: (term) ->
    switch term
      when "@"
        @reserveCharacters @n
      when "A"
        @cursorUp @n or 1
      when "B"
        @cursorDown @n or 1
      when "C"
        @cursorForward @n or 1
      when "D"
        @cursorBack @n or 1
      when "G"
        @setCursorColumn @n
      when "H"
        @setCursorPos @n or 1, @m or 1
      when "J"
        @eraseData @n or 0
      when "K"
        @eraseInLine @n or 0
      when "L"
        @insertLines @n or 1
      when "M"
        @deleteLines @n or 1
      when "d" # VPA - Vertical Position Absolute
        @setCursorLine(@n)
      when "l" # l, Reset mode
        console.log "(TODO) reset: " + @n
      when "m"
        @handleSGR @params
      when "P" # DCH - Delete Character, from current position to end of field
        @deleteCharacter @n or 1
      when "r" # Set top and bottom margins (scroll region on VT100)
        @setScrollRegion(@n, @m)
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

    @setBrush AsciiIo.Brush.create(props)

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

    changes = @changes()
    @renderer.render(changes, @cursorX, @cursorY)
    @clearChanges()

    @data.length is 0

  # ==== Screen buffer operations

  setBrush: (brush) ->
    @brush = brush

  clearScreen: ->
    @lineData.length = 0

  getLine: (n) ->
    n = (if typeof n isnt "undefined" then n else @cursorY)

    throw "cant getLine " + n  if n >= @lines

    line = @lineData[n]

    if typeof line is "undefined"
      line = @lineData[n] = []
      @fill n, 0, @cols, " "

    line

  switchToNormalBuffer: ->
    @lineData = @normalBuffer
    @updateScreen()

  switchToAlternateBuffer: ->
    @lineData = @alternateBuffer
    @updateScreen()

  setScrollRegion: (top, bottom) ->
    @topMargin = top - 1
    @bottomMargin = bottom - 1

  updateLine: (n) ->
    n = (if typeof n isnt "undefined" then n else @cursorY)
    @dirtyLines[n] = n

  updateScreen: ->
    @dirtyLines[n] = n for n in [0...@lines]

  setCursorLine: (line) ->
    oldLine = @cursorY
    @cursorY = line - 1
    @updateLine oldLine
    @updateLine()

  setCursorColumn: (col) ->
    @cursorX = col - 1
    @updateLine()

  setCursorPos: (line, col) ->
    @setCursorLine(line)
    @setCursorColumn(col)

  saveCursor: ->
    @savedCol = @cursorX
    @savedLine = @cursorY

  restoreCursor: ->
    oldLine = @cursorY

    @cursorY = @savedLine
    @cursorX = @savedCol

    @updateLine oldLine
    @updateLine()

  cursorLeft: ->
    if @cursorX > 0
      @cursorX -= 1
      @updateLine()

  cursorRight: ->
    if @cursorX < @cols
      @cursorX += 1
      @updateLine()

  cursorUp: (n) ->
    for i in [0...n]
      if @cursorY > 0
        @cursorY -= 1
        @updateLine @cursorY
        @updateLine @cursorY + 1

  cursorDown: (n) ->
    for i in [0...n]
      if @cursorY + 1 < @lines
        @cursorY += 1
        @updateLine @cursorY - 1
        @updateLine @cursorY

  cursorForward: (n) ->
    @cursorRight() for i in [0...n]

  cursorBack: (n) ->
    @cursorLeft() for i in [0...n]

  cr: ->
    @cursorX = 0
    @updateLine()

  backspace: ->
    if @cursorX > 0
      @cursorLeft()
      @updateLine()

  print: (text) ->
    text = Utf8.decode(text)

    i = 0
    while i < text.length
      if @cursorX >= @cols
        @cursorY += 1
        @cursorX = 0

      @fill @cursorY, @cursorX, 1, text[i]
      @cursorX += 1
      i++

    @updateLine()

  eraseData: (n) ->
    if n is 0
      @eraseInLine 0

      l = @cursorY + 1
      while l < @lines
        @clearLineData l
        @updateLine l
        l++

    else if n is 1
      l = 0
      while l < @cursorY
        @clearLineData l
        @updateLine l
        l++

      @eraseInLine n

    else if n is 2
      l = 0
      while l < @lines
        @clearLineData l
        @updateLine l
        l++

  eraseInLine: (n) ->
    if n is 0
      @fill @cursorY, @cursorX, @cols - @cursorX, " "
    else if n is 1
      @fill @cursorY, 0, @cursorX, " "
    else if n is 2
      @fill @cursorY, 0, @cols, " "

    @updateLine()

  clearLineData: (n) ->
    @fill n, 0, @cols, " "

  deleteCharacter: (n) ->
    @getLine().splice(@cursorX, n)
    @updateLine()

  reserveCharacters: (n) ->
    line = @getLine()
    @lineData[@cursorY] = line.slice(0, @cursorX).concat(" ".times(n).split(""), line.slice(@cursorX, @cols - n))
    @updateLine()

  lineFeed: ->
    @index()

  index: ->
    if @cursorY + 1 < @lines
      @cursorDown()
    else
      @lineData.splice 0, 1
      @updateScreen()

  reverseIndex: ->
    if @cursorY is 0
      @insertLines 1, 0
    else
      @cursorUp()

  insertLines: (n, l = @cursorY) ->
    i = 0
    while i < n
      @lineData.splice l, 0, []
      @clearLineData l
      i++

    # trim lineData to max size
    @lineData.length = @lines

    @updateScreen()

  deleteLines: (n, l = @cursorY) ->
    @lineData.splice l, n

    # expand lineData to max size
    @lineData.length = @lines

    @updateScreen()

  fill: (line, col, n, char) ->
    lineArr = @getLine(line)

    i = 0
    while i < n
      lineArr[col + i] = [char, @brush]
      i++

  changes: ->
    c = {}
    for _, n of @dirtyLines
      c[n] = @lineData[n]

    c

  clearChanges: ->
    @dirtyLines = {}
