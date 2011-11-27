class AsciiIo.Terminal
  constructor: (cols, lines) ->
    @element = $(".player .term")
    @cols = cols
    @lines = lines
    @cursorX = 0
    @cursorY = 0
    @normalBuffer = []
    @alternateBuffer = []
    @lineData = @normalBuffer
    @dirtyLines = []
    @fg = @bg = undefined

    @createChildElements()
    @showCursor true

    # this.updateScreen();
    # this.render();
    #
    # this.renderLine(0); // we only need 1 line
    # this.element.css({ width: this.element.width(), height: this.element.height() });

  createChildElements: ->
    i = 0

    while i < @lines
      row = $("<span class=\"line\">")
      @element.append row
      @element.append "\n"
      i++

  getLine: (n) ->
    n = (if typeof n isnt "undefined" then n else @cursorY)

    throw "cant getLine " + n  if n >= @lines

    line = @lineData[n]

    if typeof line is "undefined"
      line = @lineData[n] = []
      @fill n, 0, @cols, " "

    line

  clearScreen: ->
    # this.lineData.length = 0;
    @cursorY = @cursorX = 0
    @element.find(".line").empty()

  switchToNormalBuffer: ->
    @lineData = @normalBuffer
    @updateScreen()

  switchToAlternateBuffer: ->
    @lineData = @alternateBuffer
    @updateScreen()

  renderLine: (n) ->
    html = @getLine(n)

    if n is @cursorY
      html = html.slice(0, @cursorX).concat([ "<span class=\"cursor\">" + (html[@cursorX] or "") + "</span>" ], html.slice(@cursorX + 1) or [])

    @element.find(".line:eq(" + n + ")").html html.join("")

  render: ->
    updated = []

    i = 0
    while i < @dirtyLines.length
      n = @dirtyLines[i]
      if updated.indexOf(n) is -1
        @renderLine n
        updated.push n
      i++

    @dirtyLines = []

  updateLine: (n) ->
    n = (if typeof n isnt "undefined" then n else @cursorY)
    @dirtyLines.push n

  updateScreen: ->
    @dirtyLines = []

    l = 0
    while l < @lines
      @dirtyLines.push l
      l++

  showCursor: (show) ->
    if show
      @element.addClass "cursor-on"
    else
      @element.removeClass "cursor-on"

  setSGR: (codes) ->
    codes = [0] if codes.length is 0

    i = 0
    while i < codes.length
      n = codes[i]

      if n is 0
        @fg = @bg = undefined
        @bright = false
      else if n is 1
        @bright = true
      else if n >= 30 and n <= 37
        @fg = n - 30
      else if n >= 40 and n <= 47
        @bg = n - 40
      else if n is 38
        @fg = codes[i + 2]
        i += 2
      else if n is 48
        @bg = codes[i + 2]
        i += 2
      i++

  setCursorPos: (line, col) ->
    line -= 1
    col -= 1
    oldLine = @cursorY
    @cursorY = line
    @cursorX = col
    @updateLine oldLine
    @updateLine()

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

  cursorUp: ->
    if @cursorY > 0
      @cursorY -= 1
      @updateLine @cursorY
      @updateLine @cursorY + 1

  cursorDown: ->
    if @cursorY + 1 < @lines
      @cursorY += 1
      @updateLine @cursorY - 1
      @updateLine @cursorY
    else
      @lineData.splice 0, 1
      @updateScreen()

  cursorForward: (n) ->
    i = 0
    while i < n
      @cursorRight()
      i++

  cursorBack: (n) ->
    i = 0
    while i < n
      @cursorLeft()
      i++

  cr: ->
    @cursorX = 0
    @updateLine()

  bs: ->
    if @cursorX > 0
      @getLine()[@cursorX - 1] = " "
      @cursorX -= 1
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
      @updateLine()
    else if n is 1
      @fill @cursorY, 0, @cursorX, " "
      @updateLine()
    else if n is 2
      @fill @cursorY, 0, @cols, " "
      @updateLine()

  clearLineData: (n) ->
    @fill n, 0, @cols, " "

  reserveCharacters: (n) ->
    line = @getLine()
    @lineData[@cursorY] = line.slice(0, @cursorX).concat(" ".times(n).split(""), line.slice(@cursorX, @cols - n))
    @updateLine()

  ri: (n) ->
    i = 0
    while i < n
      if @cursorY is 0
        @insertLines 0, n
      else
        @cursorUp()
      i++

  insertLines: (l, n) ->
    i = 0
    while i < n
      @lineData.splice l, 0, []
      @clearLineData l
      i++

    @lineData.length = @lines
    @updateScreen()

  fill: (line, col, n, char) ->
    prefix = ""
    postfix = ""

    if @fg isnt undefined or @bg isnt undefined or @bright
      prefix = "<span class=\""
      brightOffset = (if @bright then 8 else 0)

      if @fg isnt undefined
        prefix += " fg" + (@fg + brightOffset)
      else if @bright
        prefix += " bright"

      prefix += " bg" + @bg if @bg isnt undefined
      prefix += "\">"
      postfix = "</span>"

    char = prefix + char + postfix
    lineArr = @getLine(line)

    i = 0
    while i < n
      lineArr[col + i] = char
      i++

  blinkCursor: ->
    cursor = @element.find(".cursor")
    if cursor.hasClass("inverted")
      cursor.removeClass "inverted"
    else
      cursor.addClass "inverted"

  restartCursorBlink: ->
    if @cursorTimerId
      clearInterval @cursorTimerId
      @cursorTimerId = null

    @cursorTimerId = setInterval(@blinkCursor.bind(this), 500)
