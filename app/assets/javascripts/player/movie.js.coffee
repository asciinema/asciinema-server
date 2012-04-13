class AsciiIo.Movie
  MIN_DELAY: 0.01

  constructor: (@model, @options) ->
    @reset()
    @startTimeReporter()
    _.extend(this, Backbone.Events)

  reset: ->
    @frameNo = 0
    @dataIndex = 0
    @playedTimeSum = 0
    @playing = false
    @lastFrameTime = undefined
    @timeElapsedBeforePause = undefined
    @framesProcessed = 0

  isLoaded: ->
    @model.get('escaped_stdout_data') != undefined

  load: ->
    @model.fetch
      success: =>
        @trigger('movie-loaded', @model)

  timing: ->
    @model.get('stdout_timing_data')

  data: ->
    unless @_data
      d = @model.get('escaped_stdout_data')
      d = eval "'" + d + "'"
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
      @startTime = (new Date).getTime()

    @playing = true
    @lastFrameTime = (new Date()).getTime()
    @nextFrame()

  stop: ->
    @playing = false
    clearInterval @nextFrameTimeoutId
    @timeElapsedBeforePause = (new Date()).getTime() - @lastFrameTime

  restart: ->
    @reset()
    @start()
    @startTimeReporter()

  pause: ->
    return if @isPaused()

    @stop()
    @trigger('movie-playback-paused')

  resume: ->
    return if @isPlaying()

    @playing = true
    frame = @timing()[@frameNo]
    [delay, count] = frame
    delay -= @timeElapsedBeforePause
    @processFrameWithDelay(delay)
    @trigger('movie-playback-resumed')

  togglePlay: ->
    if @isPlaying() then @pause() else @play()

  isPlaying: ->
    @playing

  isPaused: ->
    !@isPlaying() and !@isFinished() and @frameNo > 0

  isFinished: ->
    !@isPlaying() and @isLoaded() and @frameNo >= @timing().length

  seek: (percent) ->
    @pause()
    @rewindTo(percent)
    @play()

  rewindTo: (percent) ->
    # TODO

  startTimeReporter: ->
    @timeReportId = setInterval(
      => @trigger('movie-time', @currentTime())
      100
    )

  stopTimeReporter: ->
    clearInterval @timeReportId

  currentTime: ->
    if @isPlaying()
      now = (new Date()).getTime()
      delta = now - @lastFrameTime
      @playedTimeSum + delta
    else if @isPaused()
      @playedTimeSum + @timeElapsedBeforePause
    else if @isFinished()
      @playedTimeSum
    else
      0 # not started

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
      @stopTimeReporter()
      @trigger('movie-finished')

      if @options.benchmark
        now = (new Date).getTime()
        console.log "finished in #{(now - @startTime) / 1000.0}s"

      false

  processFrameWithDelay: (delay) ->
    @nextFrameTimeoutId = setTimeout(
      =>
        @trigger('movie-awake')
        @processFrame()
      delay
    )

  processFrame: ->
    frame = @timing()[@frameNo]
    [delay, count] = frame

    frameData = @data().slice(@dataIndex, @dataIndex + count)
    @trigger('movie-frame', frameData)

    @frameNo += 1
    @dataIndex += count
    @playedTimeSum += delay * 1000
    @lastFrameTime = (new Date()).getTime()

    @nextFrame()
