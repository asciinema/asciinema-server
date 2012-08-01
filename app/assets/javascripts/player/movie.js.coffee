class AsciiIo.Movie
  MIN_DELAY: 0.01

  constructor: (@options) ->
    _.extend(this, Backbone.Events)
    @reset()
    @startTimeReporter()

  reset: ->
    @frameNo = 0
    @dataIndex = 0
    @completedFramesTime = 0
    @playing = false
    @lastFrameAt = undefined
    @framesProcessed = 0
    @clearPauseState()
    @trigger 'reset'

  call: (method, args...) ->
    @[method].apply this, args

  now: ->
    (new Date()).getTime()

  timing: ->
    @options.timing

  data: ->
    @options.stdout_data

  play: ->
    return if @isPlaying()

    if @isFinished()
      @restart()
    else if @isPaused()
      @resume()
    else
      @start()

  start: ->
    @playing = true
    @trigger 'started'
    @lastFrameAt = @now()
    @nextFrame()

  stop: ->
    @playing = false
    @cancelNextFrameProcessing()
    now = @now()
    @adjustFrameWaitTime(now)
    @pausedAt = now

  cancelNextFrameProcessing: ->
    clearInterval @nextFrameTimeoutId

  adjustFrameWaitTime: (now) ->
    resumedAt = @resumedAt or @lastFrameAt
    currentWaitTime = now - resumedAt
    @totalFrameWaitTime += currentWaitTime

  restart: ->
    @reset()
    @start()

  pause: ->
    return if @isPaused()

    @stop()
    @trigger 'paused'

  resume: ->
    return if @isPlaying()

    @playing = true
    @resumedAt = @now()
    frame = @timing()[@frameNo]
    [delay, count] = frame
    delayMs = delay * 1000
    delayLeft = delayMs - @totalFrameWaitTime
    @processFrameWithDelay(delayLeft)
    @trigger 'resumed'

  togglePlay: ->
    if @isPlaying() then @pause() else @play()

  isPlaying: ->
    @playing

  isPaused: ->
    !@isPlaying() and !@isFinished() and @frameNo > 0

  isFinished: ->
    !@isPlaying() and @frameNo >= @timing().length

  seek: (percent) ->
    @stop()
    @rewindTo(percent)
    @resume()

  rewindTo: (percent) ->
    duration = @options.duration
    requestedTime = duration * percent / 100

    frameNo = 0
    time = 0
    totalCount = 0
    delay = undefined
    count = undefined

    while time < requestedTime
      [delay, count] = @timing()[frameNo]

      if time + delay >= requestedTime
        break

      time += delay
      totalCount += count
      frameNo += 1

    @frameNo = frameNo
    @completedFramesTime = time * 1000
    @dataIndex = totalCount

    data = @data().slice(0, totalCount)
    @trigger 'reset'
    @trigger 'data', [data]

    @lastFrameAt = @now()
    wait = requestedTime - time
    @totalFrameWaitTime = wait * 1000

  startTimeReporter: ->
    @timeReportId = setInterval(
      => @trigger('time', @currentTime())
      500
    )

  stopTimeReporter: ->
    clearInterval @timeReportId

  currentTime: ->
    @completedFramesTime + @currentFrameTime()

  currentFrameTime: ->
    if @isPlaying()
      @playingFrameTime()
    else if @isPaused()
      @pausedFrameTime()
    else
      0

  playingFrameTime: ->
    if @frameWasPaused()
      @currentFrameWithPauseTime()
    else
      @currentFrameWithNoPauseTime()

  frameWasPaused: ->
    !!@pausedAt

  currentFrameWithPauseTime: ->
    @totalFrameWaitTime + @sinceResumeTime()

  currentFrameWithNoPauseTime: ->
    @now() - @lastFrameAt

  sinceResumeTime: ->
    @now() - @resumedAt

  pausedFrameTime: ->
    @totalFrameWaitTime

  clearPauseState: ->
    @pausedAt = undefined
    @resumedAt = undefined
    @totalFrameWaitTime = 0

  nextFrame: ->
    if frame = @timing()[@frameNo]
      [delay, count] = frame

      if delay <= @MIN_DELAY and @framesProcessed < 100
        @framesProcessed += 1
        @processFrame()
      else
        @framesProcessed = 0
        realDelay = delay * 1000 * (1.0 / @options.speed)
        @processFrameWithDelay(realDelay)

      true
    else
      @playing = false
      @trigger 'finished'

      false

  processFrameWithDelay: (delay) ->
    @nextFrameTimeoutId = setTimeout(
      =>
        @trigger 'wakeup'
        @processFrame()
      delay
    )

  processFrame: ->
    frame = @timing()[@frameNo]
    [delay, count] = frame

    frameData = @data().slice(@dataIndex, @dataIndex + count)
    @trigger 'data', [frameData]

    @frameNo += 1
    @dataIndex += count
    @completedFramesTime += delay * 1000
    @lastFrameAt = @now()

    @clearPauseState()
    @nextFrame()
