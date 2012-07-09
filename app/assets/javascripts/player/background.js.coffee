vt = undefined
movie = undefined

@onmessage = (e) =>
  d = e.data

  if d.objectName
    switch d.objectName
      when 'vt'
        vt[d.message](d.args[0], d.args[1], d.args[2])

      when 'movie'
        movie[d.message](d.args[0], d.args[1], d.args[2])

  else if d.cmd
    switch d.cmd
      when 'init'
        initialize d

initialize = (options) ->
  vt = new AsciiIo.VT options.cols, options.lines
  vt.on 'all', (event) -> postMessage evt: event, src: 'vt'

  movie = new AsciiIo.Movie(
    timing: options.timing
    stdout_data: options.stdout_data
    duration: options.duration
    speed: options.speed
    benchmark: options.benchmark
    cols: options.cols
    lines: options.lines
  )

  movie.on 'all', (event, arg1) -> postMessage evt: event, src: 'movie', arg1: arg1

  movie.on 'reset', => vt.reset()
  movie.on 'finished', => vt.stopCursorBlink()
  movie.on 'wakeup', => vt.restartCursorBlink()

  movie.on 'data', (data) =>
    vt.feed data
    state = vt.state()
    # console.log state
    vt.clearChanges()
    movie.trigger 'render', state

  console.log 'inited!'
