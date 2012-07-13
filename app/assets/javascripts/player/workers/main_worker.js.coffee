vt = undefined
movie = undefined

@onmessage = (e) =>
  d = e.data

  if d.objectName
    switch d.objectName
      when 'vt'
        vt[d.method](d.args...)

      when 'movie'
        movie[d.method](d.args...)

  else if d.cmd
    switch d.cmd
      when 'init'
        initialize d.options

initialize = (options) ->
  vt = new AsciiIo.VT options.cols, options.lines
  vt.on 'all', (event, args...) ->
    postMessage evt: event, src: 'vt', args: args

  movie = new AsciiIo.Movie(
    timing: options.timing
    stdout_data: options.stdout_data
    duration: options.duration
    speed: options.speed
    benchmark: options.benchmark
    cols: options.cols
    lines: options.lines
  )

  movie.on 'all', (event, args...) ->
    postMessage evt: event, src: 'movie', args: args

  movie.on 'reset', => vt.reset()
  movie.on 'finished', => vt.stopCursorBlink()
  movie.on 'wakeup', => vt.restartCursorBlink()

  lastRenderTime = (new Date()).getTime()

  movie.on 'data', (data) =>
    vt.feed data

    now = (new Date()).getTime()

    if now - lastRenderTime > 40
      state = vt.state()
      vt.clearChanges()
      movie.trigger 'render', state

      lastRenderTime = now

  console.log 'inited!'
