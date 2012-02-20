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
    "\x09": (data) -> @goToNextHorizontalTabStop()
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

  handleCSI: (term) ->
    switch term
      when "@"
        @insertCharacters @n
      when "A"
        @priorRow @n
      when "B"
        @nextRow @n
      when "C"
        @nextColumn @n
      when "D"
        @priorColumn @n
      when "E"
        @nextRowFirstColumn @n
      when "F"
        @priorRowFirstColumn @n
      when "G"
        @goToColumn @n
      when "H"
        @goToRowAndColumn @n, @m
      when "I"
        @goToNextHorizontalTabStop @n
      when "J"
        if @n is 2
          @eraseScreen()
        else if @n is 1
          @eraseFromScreenStart()
        else
          @eraseToScreenEnd()
      when "K"
        if @n is 2
          @eraseRow()
        else if @n is 1
          @eraseFromRowStart()
        else
          @eraseToRowEnd()
      when "L"
        @insertLine @n or 1
      when "M"
        @deleteLine @n or 1
      when "P" # DCH - Delete Character, from current position to end of field
        @deleteCharacters @n or 1
      when "S"
        @scrollUp @n
      when "T"
        @scrollDown @n
      when "X"
        @eraseCharacters @n
      when "Z"
        @goToPriorHorizontalTabStop @n
      when "b"
        @repeatLastCharacter @n
      when "d" # VPA - Vertical Position Absolute
        @goToRow @n
      when "f"
        @goToRowAndColumn @n, @m
      when "g"
        if !@n or @n is 0
          @clearHorizontalTabStop()
        else if @n is 3
          @clearAllHorizontalTabStops()
      when "l" # l, Reset mode
        console.log "(TODO) reset: " + @n
      when "m"
        @handleSGR @params
      when "n"
        @reportRowAndColumn()
      when "r" # Set top and bottom margins (scroll region on VT100)
        @setScrollRegion @n or 0, @m or @lines - 1
      when "s"
        @saveCursor()
      when "u"
        @restoreCursor()
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

    @render()

    @data.length is 0

  render: ->
    changes = @changes()
    @renderer.render(changes, @cursorX, @cursorY)
    @clearChanges()

  # ==== Screen buffer operations

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

  updateLine: (n = @cursorY) ->
    @dirtyLines[n] = @lineData[n]

  updateLines: (a, b) ->
    n = a
    while n <= b
      @updateLine n
      n++

  updateScreen: ->
    @updateLine n for n in [0...@lines]

  carriageReturn: ->
    @goToFirstColumn()

  backspace: ->
    @priorColumn()

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

  clearLineData: (n) ->
    @fill n, 0, @cols, " "

  fill: (line, col, n, char, brush=@brush) ->
    lineArr = @getLine(line)

    i = 0
    while i < n
      lineArr[col + i] = [char, brush]
      i++

  inScrollRegion: ->
    @cursorY >= @topMargin and @cursorY <= @bottomMargin

  changes: ->
    @dirtyLines

  clearChanges: ->
    @dirtyLines = {}

  # === ANSI handlers

  # ------ Cursor control

  # ----- Scroll control

  reverseIndex: ->
    @goToPriorRow()

  lineFeed: ->
    @goToNextRow()

  verticalTab: ->
    @goToNextRow()

  formFeed: ->
    @goToNextRow()

  index: ->
    @goToNextRow()

  newLine: ->
    @goToNextRowFirstColumn()


  # === Commands

  # ----- Cursor control

  priorRow: (n = 1) ->
    for i in [0...n]
      if @cursorY > 0
        @cursorY -= 1
        @updateLine @cursorY
        @updateLine @cursorY + 1

  nextRow: (n = 1) ->
    for i in [0...n]
      if @cursorY + 1 < @lines
        @cursorY += 1
        @updateLine @cursorY - 1
        @updateLine @cursorY

  nextColumn: (n = 1) ->
    @_cursorRight() for i in [0...n]

  priorColumn: (n = 1) ->
    @_cursorLeft() for i in [0...n]

  _cursorLeft: ->
    if @cursorX > 0
      @cursorX -= 1
      @updateLine()

  _cursorRight: ->
    if @cursorX < @cols - 1
      @cursorX += 1
      @updateLine()

  priorRowFirstColumn: (n = 1) ->
    @carriageReturn()
    @priorRow n

  nextRowFirstColumn: (n = 1) ->
    @carriageReturn()
    @nextRow n

  goToColumn: (col = 1) ->
    @cursorX = col - 1
    @updateLine()

  goToRow: (line = 1) ->
    oldLine = @cursorY
    @cursorY = line - 1
    @updateLine oldLine
    @updateLine()

  goToRowAndColumn: (line = 1, col = 1) ->
    @goToRow line
    @goToColumn col

  setHorizontalTabStop: ->
    unless _(@tabStops).include(@cursorX)
      pos = _(@tabStops).sortedIndex(@cursorX)
      @tabStops.splice(pos, 0, @cursorX)

  goToNextHorizontalTabStop: (n) ->
    x = @getNextTabStop()
    @goToRowAndColumn(@cursorY + 1, x + 1)
    @updateLine()

  goToPriorHorizontalTabStop: (n) ->
    x = @getPriorTabStop()
    @goToRowAndColumn(@cursorY + 1, x + 1)
    @updateLine()

  getNextTabStop: ->
    for x in @tabStops
      if x > @cursorX
        return x

    @cols

  getPriorTabStop: ->
    ret = 0

    for x in @tabStops
      if x > @cursorX
        break

      ret = x

    ret

  clearHorizontalTabStop: ->
    console.log 'clearHorizontalTabStop'

  clearAllHorizontalTabStops: ->
    console.log 'clearAllHorizontalTabStops'

  saveCursor: ->
    @savedCol = @cursorX
    @savedLine = @cursorY

  restoreCursor: ->
    oldLine = @cursorY

    @cursorY = @savedLine
    @cursorX = @savedCol

    @updateLine oldLine
    @updateLine()

  showCursor: ->
    @renderer.showCursor true

  hideCursor: ->
    @renderer.showCursor false

  goToFirstColumn: ->
    @cursorX = 0
    @updateLine()

  # ----- Scroll control

  setScrollRegion: (top, bottom) ->
    @topMargin = top - 1
    @bottomMargin = bottom - 1

  setLineWrap: (linewrap) ->

  scrollUp: (n = 1) ->
    @insertLine n, @topMargin

  scrollDown: (n = 1) ->
    @deleteLine n, @topMargin

  _addEmptyLine: (l) ->
    @lineData.splice l, 0, []
    @clearLineData l

  _removeLine: (l) ->
    @lineData.splice l, 1

  insertLine: (n, l = @cursorY) ->
    return unless @inScrollRegion()

    i = 0
    while i < n
      @_removeLine @bottomMargin
      @_addEmptyLine l
      i++

    @updateLines(l, @bottomMargin)

  deleteLine: (n, l = @cursorY) ->
    return unless @inScrollRegion()

    i = 0
    while i < n
      @_removeLine l
      @_addEmptyLine @bottomMargin
      i++

    @updateLines(l, @bottomMargin)

  deleteCharacters: (n) ->
    line = @getLine()
    brush = line[line.length-1][1]
    line.splice(@cursorX, n)
    @fill(@cursorY, @cols - n, n, ' ', brush)
    @updateLine()

  insertCharacters: (n) ->
    line = @getLine()
    @lineData[@cursorY] = line.slice(0, @cursorX).concat(" ".times(n).split(""), line.slice(@cursorX, @cols - n))
    @updateLine()

  goToPriorRow: ->
    if @cursorY is @topMargin
      @scrollUp()
    else
      @priorRow()

  goToNextRow: ->
    if @cursorY is @bottomMargin
      @scrollDown()
    else
      @nextRow()

  goToNextRowFirstColumn: ->
    @carriageReturn()
    @goToNextRow()

  saveScrollRegion: ->
    @savedTopMargin = @topMargin
    @savedBottomMargin = @bottomMargin

  restoreScrollRegion: ->
    @topMargin = @savedTopMargin
    @bottomMargin = @savedBottomMargin

  # ----- Terminal control

  resetTerminal: ->
    @cursorX = 0
    @cursorY = 0
    @topMargin = 0
    @bottomMargin = @lines - 1
    @normalBuffer = []
    @alternateBuffer = []
    @lineData = @normalBuffer
    @dirtyLines = {}
    @brush = AsciiIo.Brush.create({})
    @tabStops = (x for x in [0...@cols] when x % 8 is 0)

    @fg = @bg = undefined
    @bright = false
    @underline = false
    @italic = false

    @updateScreen()

  saveTerminalState: ->
    @saveCursor()
    @saveScrollRegion()
    @saveBrush()

  restoreTerminalState: ->
    @restoreBrush()
    @restoreScrollRegion()
    @restoreCursor()

  reportRowAndColumn: ->

  # ----- Attribute control

  setBrush: (brush) ->
    @brush = brush

  saveBrush: ->
    @savedBrush = @brush

  restoreBrush: ->
    @brush = @savedBrush

  repeatLastCharacter: (n = 1) ->

  # ----- Erase control

  eraseScreen: ->
    l = 0
    while l < @lines
      @clearLineData l
      @updateLine l
      l++

  eraseFromScreenStart: ->
    l = 0
    while l < @cursorY
      @clearLineData l
      @updateLine l
      l++

    @eraseFromRowStart()

  eraseToScreenEnd: ->
    @eraseToRowEnd()

    l = @cursorY + 1
    while l < @lines
      @clearLineData l
      @updateLine l
      l++

  eraseRow: ->
    @fill @cursorY, 0, @cols, " "
    @updateLine()

  eraseFromRowStart: ->
    @fill @cursorY, 0, @cursorX, " "
    @updateLine()

  eraseToRowEnd: ->
    @fill @cursorY, @cursorX, @cols - @cursorX, " "
    @updateLine()

  eraseCharacters: (n = 1) ->
    @fill @cursorY, @cursorX, n, " "
    @updateLine()

# http://www.shaels.net/index.php/propterm/documents
