class AsciiIo.ScreenBuffer

  constructor: (@cols, @lines) ->
    @cursorX = 0
    @cursorY = 0
    @normalBuffer = []
    @alternateBuffer = []
    @lineData = @normalBuffer
    @dirtyLines = {}
    @brush = AsciiIo.Brush.create({})

  setBrush: (brush) ->
    @brush = brush

  clear: ->
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
      else
        @lineData.splice 0, 1
        @updateScreen()

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

  ri: (n=1) ->
    i = 0
    while i < n
      if @cursorY is 0
        @insertLines n, 0
      else
        @cursorUp()
      i++

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
