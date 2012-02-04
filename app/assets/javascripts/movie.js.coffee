class AsciiIo.Movie
  MIN_DELAY: 0.01
  SPEED: 1.0

  constructor: (@data, @timing) ->
    @currentTime = 0
    @processedFramesTime = 0

  play: ->
    @nextFrame()

  nextFrame: () ->
    return if @currentData.length > 100

    frame = @timing[@frameNo]

    unless frame
      @terminal.stopCursorBlink()
      console.log "finished in #{((new Date()).getTime() - @startTime) / 1000} seconds"
      return

    @frameNo += 1

    [delay, count] = frame

    if delay > @MIN_DELAY
      realDelay = delay * 1000 * (1.0 / @SPEED)

      setTimeout(
        =>
          @terminal.restartCursorBlink()
          @processFrame(count)
          @nextFrame()
        realDelay
      )
    else
      @processFrame(count)
      @nextFrame()

  processFrame: (count) ->
    @currentData += @data.slice(@dataIndex, @dataIndex + count)
    @dataIndex += count

    @currentData = @interpreter.feed(@currentData)

    if @currentData.length > 0
      @logStatus(count)

  logStatus: (count) ->
    console.log 'rest: ' + Utf8.decode(@currentData)

    if @currentData.length > 100
      head = @currentData.slice(0, 100)
      hex = ("0x#{c.charCodeAt(0).toString(16)}" for c in head)
      console.log "failed matching: '" + Utf8.decode(head) + "' (" + hex.join() + ") [pos: " + (@dataIndex - count) + "]"
      return
