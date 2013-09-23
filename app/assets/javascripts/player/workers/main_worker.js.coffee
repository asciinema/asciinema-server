movie = undefined

addEventListener 'message', (e) =>
  d = e.data

  switch d.message
    when 'init'
      @initialize d.options

    when 'call'
      switch d.objectName
        when 'movie'
          movie[d.method](d.args...)


@initialize = (options) ->
  movie = new Asciinema.Movie(
    stdout_frames: options.stdout_frames
    duration: options.duration
    speed: options.speed
    benchmark: options.benchmark
    cols: options.cols
    lines: options.lines
  )

  movie.on 'all', (event, args...) ->
    postMessage evt: event, src: 'movie', args: args

  console.log 'inited!'
