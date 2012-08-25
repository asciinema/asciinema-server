class AsciiIo.ScreenBuffer

  constructor: (@cols, @lines, @scrollRegion, @tabStops) ->
    @lineData = []
    @dirtyLines = {}

    @cursorX = 0
    @cursorY = 0

    @setBrush AsciiIo.Brush.default()
    @setCharset 'us'

  topMargin: ->
    @scrollRegion.getTop()

  bottomMargin: ->
    @scrollRegion.getBottom()

  updateLine: (n = @cursorY) ->
    @dirtyLines[n] = true

  updateLines: (a, b) ->
    n = a
    while n <= b
      @updateLine n
      n++

  updateScreen: ->
    @updateLine n for n in [0...@lines]

  changes: ->
    changes = {}

    for n, _ of @dirtyLines
      data = @lineData[n] || []

      fragments = []
      currentBrush = AsciiIo.Brush.default()
      currentText = ''

      for i in [0...@cols]
        d = data[i]

        if d
          [char, brush] = d
        else
          [char, brush] = [' ', currentBrush]

        if brush == currentBrush
          currentText += char
        else
          fragments.push([currentText, currentBrush]) if currentText.length > 0
          currentText = char
          currentBrush = brush

      fragments.push([currentText, currentBrush]) if currentText.length > 0
      changes[n] = fragments

    changes

  clearChanges: ->
    @dirtyLines = {}

  clear: ->
    @lineData.length = 0

  getLine: (n = @cursorY) ->
    throw "cant getLine " + n  if n >= @lines

    line = @lineData[n]

    if typeof line is "undefined"
      line = @lineData[n] = []
      @fill n, 0, @cols, " "

    line

  _addEmptyLine: (l) ->
    @lineData.splice l, 0, []
    @clearLineData l

  _removeLine: (l) ->
    @lineData.splice l, 1

  insertCharacters: (n) ->
    line = @getLine()
    @lineData[@cursorY] = line.slice(0, @cursorX).concat(" ".times(n).split(""), line.slice(@cursorX, @cols - n))
    @updateLine()

  fill: (line, col, n, char, brush=@brush) ->
    lineArr = @getLine(line)

    i = 0
    while i < n
      lineArr[col + i] = [char, brush]
      i++

  deleteCharacters: (n) ->
    line = @getLine()
    brush = line[line.length-1][1]
    line.splice(@cursorX, n)
    @fill(@cursorY, @cols - n, n, ' ', brush)
    @updateLine()

  print: (text) ->
    text = Utf8.decode(text)

    startLine = @cursorY

    i = 0
    while i < text.length
      if @cursorX >= @cols
        @goToNextRowFirstColumn()

      @fill @cursorY, @cursorX, 1, @charsetModifier(text[i])
      @cursorX += 1
      i++

    endLine = @cursorY

    @updateLines(startLine, endLine)

  clearLineData: (n) ->
    @fill n, 0, @cols, " "

  # ----- Cursor control

  correctCursorPos: ->
    if @cursorX < 0
      @cursorX = 0

    if @cursorX >= @cols
      @cursorX = @cols - 1

    if @cursorY < 0
      @cursorY = 0

    if @cursorY >= @lines
      @cursorY = @lines - 1

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
    @goToFirstColumn()
    @priorRow n

  nextRowFirstColumn: (n = 1) ->
    @goToFirstColumn()
    @nextRow n

  goToColumn: (col = 1) ->
    @cursorX = col - 1
    @correctCursorPos()
    @updateLine()

  goToRow: (line = 1) ->
    oldLine = @cursorY
    @cursorY = line - 1
    @correctCursorPos()

    if oldLine != @cursorY
      @updateLine oldLine

    @updateLine()

  goToRowAndColumn: (line = 1, col = 1) ->
    @goToRow line
    @goToColumn col

  goToNextHorizontalTabStop: (n) ->
    x = @tabStops.next(@cursorX)
    @goToRowAndColumn(@cursorY + 1, x + 1)
    @updateLine()

  goToPriorHorizontalTabStop: (n) ->
    x = @tabStops.prev(@cursorX)
    @goToRowAndColumn(@cursorY + 1, x + 1)
    @updateLine()

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

  goToFirstColumn: ->
    @cursorX = 0
    @updateLine()

  # ----- Attribute control

  setBrush: (brush) ->
    @brush = brush

  getBrush: ->
    @brush

  saveBrush: ->
    @savedBrush = @brush

  restoreBrush: ->
    @brush = @savedBrush

  repeatLastCharacter: (n = 1) ->

  updateBrush: (changes) ->
    attrs = _.extend({}, @brush.attributes(), changes)
    @brush = AsciiIo.Brush.create attrs

  # ----- Scroll control

  inScrollRegion: ->
    @cursorY >= @topMargin() and @cursorY <= @bottomMargin()

  scrollUp: (n = 1) ->
    @insertLine n, @topMargin()

  scrollDown: (n = 1) ->
    @deleteLine n, @topMargin()

  insertLine: (n, l = @cursorY) ->
    return unless @inScrollRegion()

    i = 0
    while i < n
      @_removeLine @bottomMargin()
      @_addEmptyLine l
      i++

    @updateLines(l, @bottomMargin())

  deleteLine: (n, l = @cursorY) ->
    return unless @inScrollRegion()

    i = 0
    while i < n
      @_removeLine l
      @_addEmptyLine @bottomMargin()
      i++

    @updateLines(l, @bottomMargin())

  goToPriorRow: ->
    if @cursorY is @topMargin()
      @scrollUp()
    else
      @priorRow()

  goToNextRow: ->
    if @cursorY is @bottomMargin()
      @scrollDown()
    else
      @nextRow()

  goToNextRowFirstColumn: ->
    @goToFirstColumn()
    @goToNextRow()

  setLineWrap: (linewrap) ->

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

  # ------ Charset control

  setCharset: (charset) ->
    @charset = charset

    switch charset
      when 'uk'
        @charsetModifier = @ukCharsetModifier
      when 'us'
        @charsetModifier = @usCharsetModifier
      when 'special'
        @charsetModifier = @specialCharsetModifier

  getCharset: ->
    @charset

  usCharsetModifier: (char) ->
    char

  ukCharsetModifier: (char) ->
    char

  specialCharsetModifier: (char) ->
    AsciiIo.SpecialCharset[char.charCodeAt(0)] or char

