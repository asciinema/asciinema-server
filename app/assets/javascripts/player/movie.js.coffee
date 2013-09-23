class Asciinema.Movie
  MIN_DELAY: 0.01

  constructor: (@options) ->
    _.extend(this, Backbone.Events)
    @reset()
    @startTimeReporter()

  reset: ->
    @frameNo = 0
    @completedFramesTime = 0
    @playing = false
    @lastFrameAt = undefined
    @clearPauseState()

  call: (method, args...) ->
    @[method].apply this, args

  now: ->
    (new Date()).getTime()

  stdout_frames: ->
    @options.stdout_frames

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
    [delay, changes] = @stdout_frames()[@frameNo]
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
    !@isPlaying() and @frameNo >= @stdout_frames().length

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
    delay = data = undefined

    while time < requestedTime
      [delay, changes] = @stdout_frames()[frameNo]

      if time + delay >= requestedTime
        break

      @trigger 'render', changes
      time += delay
      frameNo += 1

    @frameNo = frameNo
    @completedFramesTime = time * 1000

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
    frame = @stdout_frames()[@frameNo]

    if not frame or frame.length is 0
      @playing = false
      @trigger 'finished'

      return false

    [delay, changes] = frame

    realDelay = delay * 1000 * (1.0 / @options.speed)
    @processFrameWithDelay(realDelay)

    true

  processFrameWithDelay: (delay) ->
    @nextFrameTimeoutId = setTimeout(
      =>
        @trigger 'wakeup'
        @processFrame()
      delay
    )

  processFrame: ->
    [delay, changes] = @stdout_frames()[@frameNo]
    @trigger 'render', changes

    @frameNo += 1
    @completedFramesTime += delay * 1000
    @lastFrameAt = @now()

    @clearPauseState()
    @nextFrame()
