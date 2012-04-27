class AsciiIo.VT

  constructor: (@cols, @lines, @view) ->
    @sgrInterpreter = new AsciiIo.SgrInterpreter()
    @reset()

  reset: ->
    @data = ''
    @resetTerminal()

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

    else if match = data.match(/^\x1b[\x20-\x2f]*?[\x40-\x5a\x5c-\x7e]/) # excluding \x5b "["
      @handleStandardEscSeq(match[0])
      return match[0].length

    else if data.match(/^\x1b\x7f/) # DELETE
      return 2

    else if data.match(/^[\x00-\x1a\x1c-\x1f]/) # excluding \x1b "ESC"
      @handleControlCharacter(data[0])
      return 1

    else if match = data.match(/^([\x20-\x7e]|[\xe2\xe3]..|[\xa1-\xfe])+/)
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
    switch char
      when "\x07"
        @bell()
      when "\x08"
        @backspace()
      when "\x09"
        @buffer.goToNextHorizontalTabStop()
        # @tab()
      when "\x0a"
        @lineFeed()
      when "\x0b"
        @verticalTab()
      when "\x0c"
        @formFeed()
      when "\x0d"
        @carriageReturn()

      when "\x84"
        @index() # "ESC D"
      when "\x85"
        @newLine() # "ESC E"
      when "\x88"
        @setHorizontalTabStop() # "ESC H"
      when "\x8d"
        @reverseIndex() # "ESC M"

  handlePrintableCharacters: (text) ->
    @buffer.print text

  handleStandardEscSeq: (data) ->
    last = data[data.length - 1]
    intermediate = data[data.length - 2]

    switch last
      when "A"
        if intermediate is '('
          @setUkCharset()
      when "B"
        if intermediate is '('
          @setUsCharset()
      when "D"
        @index()
      when "E"
        @newLine()
      when "H"
        @setHorizontalTabStop()
      when "M"
        @reverseIndex()
      when "c"
        @resetTerminal()

  handlePrivateEscSeq: (data) ->
    last = data[data.length - 1]
    intermediate = data[data.length - 2]

    switch last
      when "0"
        if intermediate is '('
          @setSpecialCharset()
      when "7"
        @saveTerminalState()
      when "8"
        @restoreTerminalState()

  handleControlSequence: (data, params, match) ->
    if params and params.match(/^[\x3c-\x3f]/)
      @handlePrivateControlSequence(data, params)
    else
      @handleStandardControlSequence(data, params)

  handleStandardControlSequence: (data, params) ->
    term = data[data.length - 1]

    numbers = @parseParams(params)
    n = numbers[0]
    m = numbers[1]

    switch term
      when "@"
        @buffer.insertCharacters n
      when "A"
        @buffer.priorRow n
      when "B"
        @buffer.nextRow n
      when "C"
        @buffer.nextColumn n
      when "D"
        @buffer.priorColumn n
      when "E"
        @buffer.nextRowFirstColumn n
      when "F"
        @buffer.priorRowFirstColumn n
      when "G"
        @buffer.goToColumn n
      when "H"
        @buffer.goToRowAndColumn n, m
      when "I"
        @buffer.goToNextHorizontalTabStop n
      when "J"
        if n is 2
          @buffer.eraseScreen()
        else if n is 1
          @buffer.eraseFromScreenStart()
        else
          @buffer.eraseToScreenEnd()
      when "K"
        if n is 2
          @buffer.eraseRow()
        else if n is 1
          @buffer.eraseFromRowStart()
        else
          @buffer.eraseToRowEnd()
      when "L"
        @buffer.insertLine n or 1
      when "M"
        @buffer.deleteLine n or 1
      when "P" # DCH - Delete Character, from current position to end of field
        @buffer.deleteCharacters n or 1
      when "S"
        @buffer.scrollUp n
      when "T"
        @buffer.scrollDown n
      when "X"
        @buffer.eraseCharacters n
      when "Z"
        @buffer.goToPriorHorizontalTabStop n
      when "b"
        @buffer.repeatLastCharacter n
      when "d" # VPA - Vertical Position Absolute
        @buffer.goToRow n
      when "f"
        @buffer.goToRowAndColumn n, m
      when "g"
        if !n or n is 0
          @buffer.clearHorizontalTabStop()
        else if n is 3
          @buffer.clearAllHorizontalTabStops()
      when "l" # l, Reset mode
        console.log "(TODO) reset: " + n
      when "m"
        @handleSGR numbers
      when "n"
        @reportRowAndColumn()
      when "r" # Set top and bottom margins (scroll region on VT100)
        if n is undefined
          n = 1
        if m is undefined
          m = @lines
        @setScrollRegion n, m

  handlePrivateControlSequence: (data, params) ->
    action = data[data.length - 1]
    modes = @parseParams(params)

    for mode in modes
      if mode is 25
        if action is "h"
          @showCursor()
        else if action is "l"
          @hideCursor()
      else if mode is 47
        if action is "h"
          @switchToAlternateBuffer()
        else if action is "l"
          @switchToNormalBuffer()
      else if mode is 1049
        if action is "h"
          # Save cursor position, switch to alternate screen buffer, and clear screen.
          @switchToAlternateBuffer()
          @clearScreen()
        else if action is "l"
          # Clear screen, switch to normal screen buffer, and restore cursor position.
          @clearScreen()
          @switchToNormalBuffer()

  parseParams: (params) ->
    if params.length is 0
      numbers = []
    else
      numbers = _(params.replace(/[^0-9;]/, '').split(';')).map (n) -> if n is '' then undefined else parseInt(n)

    numbers

  handleSGR: (numbers) ->
    @buffer.setBrush @sgrInterpreter.buildBrush(@buffer.getBrush(), numbers)

  bell: ->
    @view.visualBell()
    # @trigger('bell')

  restartCursorBlink: ->
    @view.restartCursorBlink()

  stopCursorBlink: ->
    @view.stopCursorBlink()

  feed: (data) ->
    @data += data

    while @data.length > 0
      processed = @handleData(@data)

      if processed is 0
        # console.log "no kurwa: #{@formattedData(@data)}"
        break

      @data = @data.slice(processed)

    @render()

    @data.length is 0

  formattedData: (data) ->
    head = data.slice(0, 100)
    hex = ("0x#{c.charCodeAt(0).toString(16)}" for c in head)
    Utf8.decode(head) + " (" + hex.join() + ")"

  render: ->
    @view.render(@buffer.changes(), @buffer.cursorX, @buffer.cursorY)
    @buffer.clearChanges()

  # ==== Screen buffer operations

  clearScreen: ->
    @buffer.clear()

  switchToNormalBuffer: ->
    @buffer = @normalBuffer
    @updateScreen()

  switchToAlternateBuffer: ->
    @alternateBuffer.setBrush(@normalBuffer.getBrush())
    @alternateBuffer.setCharset(@normalBuffer.getCharset())
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
    @view.showCursor true

  hideCursor: ->
    @view.showCursor false

  # ----- Scroll control

  reverseIndex: ->
    @buffer.goToPriorRow()

  lineFeed: ->
    @buffer.goToNextRow()

  verticalTab: ->
    @buffer.goToNextRow()

  formFeed: ->
    @buffer.goToNextRow()

  index: ->
    @buffer.goToNextRow()

  newLine: ->
    @buffer.goToNextRowFirstColumn()


  # === Commands

  # ----- Scroll control

  setScrollRegion: (top, bottom) ->
    if top < 1
      top = 1

    if bottom > @lines
      bottom = @lines

    if bottom > top
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

    @fg = @bg = undefined
    @bright = false
    @underline = false
    @italic = false

    @updateScreen()

  saveTerminalState: ->
    @buffer.saveCursor()
    @scrollRegion.save()
    @buffer.saveBrush()

  restoreTerminalState: ->
    @buffer.restoreBrush()
    @scrollRegion.restore()
    @buffer.restoreCursor()

  reportRowAndColumn: ->

  setUkCharset: ->
    @buffer.setCharset('uk')

  setUsCharset: ->
    @buffer.setCharset('us')

  setSpecialCharset: ->
    @buffer.setCharset('special')


# References:
# http://en.wikipedia.org/wiki/ANSI_escape_code
# http://ttssh2.sourceforge.jp/manual/en/about/ctrlseq.html
# http://real-world-systems.com/docs/ANSIcode.html
# http://www.shaels.net/index.php/propterm/documents
# http://manpages.ubuntu.com/manpages/lucid/man7/urxvt.7.html
# http://vt100.net/docs/vt102-ug/chapter5.html
