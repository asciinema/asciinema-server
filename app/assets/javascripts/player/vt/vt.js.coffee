class AsciiIo.VT

  constructor: (@cols, @lines) ->
    _.extend(this, Backbone.Events)
    @interpreter = new AsciiIo.AnsiInterpreter @onChange
    @reset()

  onChange: (action, args...) =>
    @[action](args...)

  feed: (data) ->
    @data += data
    @data = @interpreter.parse @data

    @data.length is 0

  reset: ->
    @data = ''
    @resetTerminal()

  bell: ->
    @trigger 'bell'

  state: ->
    changes: @buffer.changes()
    cursorX: @buffer.cursorX
    cursorY: @buffer.cursorY

  clearChanges: ->
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
    @trigger 'cursor-visibility', true

  hideCursor: ->
    @trigger 'cursor-visibility', false

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

  print: (text) ->
    @buffer.print text

  insertCharacters: (n) ->
    @buffer.insertCharacters n

  priorRow: (n) ->
    @buffer.priorRow n

  nextRow: (n) ->
    @buffer.nextRow n

  nextColumn: (n) ->
    @buffer.nextColumn n

  priorColumn: (n) ->
    @buffer.priorColumn n

  nextRowFirstColumn: (n) ->
    @buffer.nextRowFirstColumn n

  priorRowFirstColumn: (n) ->
    @buffer.priorRowFirstColumn n

  goToColumn: (n) ->
    @buffer.goToColumn n

  goToRowAndColumn: (n, m) ->
    @buffer.goToRowAndColumn n, m

  goToNextHorizontalTabStop: (n = 1) ->
    @buffer.goToNextHorizontalTabStop n

  eraseScreen: ->
    @buffer.eraseScreen()

  eraseFromScreenStart: ->
    @buffer.eraseFromScreenStart()

  eraseToScreenEnd: ->
    @buffer.eraseToScreenEnd()

  eraseRow: ->
    @buffer.eraseRow()

  eraseFromRowStart: ->
    @buffer.eraseFromRowStart()

  eraseToRowEnd: ->
    @buffer.eraseToRowEnd()

  insertLine: (n) ->
    @buffer.insertLine n

  deleteLine: (n) ->
    @buffer.deleteLine n

  deleteCharacters: (n) ->
    @buffer.deleteCharacters n

  scrollUp: (n) ->
    @buffer.scrollUp n

  scrollDown: (n) ->
    @buffer.scrollDown n

  eraseCharacters: (n) ->
    @buffer.eraseCharacters n

  goToPriorHorizontalTabStop: (n) ->
    @buffer.goToPriorHorizontalTabStop n

  repeatLastCharacter: (n) ->
    @buffer.repeatLastCharacter n

  goToRow: (n) ->
    @buffer.goToRow n

  clearHorizontalTabStop: ->
    @buffer.clearHorizontalTabStop()

  clearAllHorizontalTabStops: ->
    @buffer.clearAllHorizontalTabStops()

  updateBrush: (attrs) ->
    @buffer.updateBrush attrs

# References:
# http://en.wikipedia.org/wiki/ANSI_escape_code
# http://ttssh2.sourceforge.jp/manual/en/about/ctrlseq.html
# http://real-world-systems.com/docs/ANSIcode.html
# http://www.shaels.net/index.php/propterm/documents
# http://manpages.ubuntu.com/manpages/lucid/man7/urxvt.7.html
# http://vt100.net/docs/vt102-ug/chapter5.html
