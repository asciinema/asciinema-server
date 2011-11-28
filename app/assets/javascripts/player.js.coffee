class AsciiIo.Player
  constructor: (cols, lines, data, time) ->
    @minDelay = 0.01
    @speed = 1.0
    @terminal = new AsciiIo.Terminal(cols, lines)
    @interpreter = new AsciiIo.AnsiInterpreter(@terminal)
    @data = data
    @time = time
    @dataIndex = 0
    @frame = 0
    @currentData = ""
    console.log "started"
    @nextFrame()

  nextFrame: () ->
    timing = @time[@frame]

    unless timing
      console.log "finished"
      return

    @terminal.restartCursorBlink()

    run = () =>
      rest = @interpreter.feed(@currentData)
      @terminal.render()
      n = timing[1]

      if rest.length > 0
        console.log 'rest: ' + Utf8.decode(rest)

      @currentData = rest + @data.slice(@dataIndex, @dataIndex + n)
      @dataIndex += n
      @frame += 1

      if rest.length > 20
        head = rest.slice(0, 10)
        hex = ("0x#{c.charCodeAt(0).toString(16)}" for c in head)
        console.log "failed matching: '" + Utf8.decode(head) + "' (" + hex.join() + ")"
        return

      unless window.stopped
        @nextFrame()

    if timing[0] > @minDelay
      setTimeout(run, timing[0] * 1000 * (1.0 / @speed))
    else
      run()


# $(function() {
#   $(window).bind('keyup', function(event) {
#       if (event.keyCode == 27) {
#         window.stopped = true
#       }
#   })
# })
