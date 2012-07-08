class AsciiIo.Movie
  MIN_DELAY: 0.01

  constructor: (@model, @options) ->
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

  now: ->
    (new Date()).getTime()

  isLoaded: ->
    @model.get('escaped_stdout_data') != undefined

  load: ->
    @model.fetch success: => @onLoaded()

  onLoaded: ->
    if typeof window.Worker == 'function'
      @unpackViaWorker()
    else
      @trigger 'loaded', @model

  unpackViaWorker: ->
    worker = new Worker(window.worker_unpack_path)

    worker.onmessage = (event) =>
      @_data = event.data
      @trigger 'loaded', @model

    data = @model.get('escaped_stdout_data')
    data = atob(data)
    worker.postMessage(data)

  timing: ->
    @model.get('stdout_timing_data')

  data: ->
    unless @_data
      # Web Worker fallback
      d = @model.get('escaped_stdout_data')
      d = atob(d)
      d = ArchUtils.bz2.decode(d)
      @_data = d

    @_data

  play: ->
    return if @isPlaying()

    if @isFinished()
      @restart()
    else if @isPaused()
      @resume()
    else
      @start()

  start: ->
    if @options.benchmark
      @startedAt = @now()

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
    !@isPlaying() and @isLoaded() and @frameNo >= @timing().length

  seek: (percent) ->
    @stop()
    @rewindTo(percent)
    @resume()

  rewindTo: (percent) ->
    duration = @model.get('duration')
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
      100
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

      if @options.benchmark
        console.log "finished in #{(@now() - @startedAt) / 1000.0}s"

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
