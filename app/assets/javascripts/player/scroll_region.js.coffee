class AsciiIo.ScrollRegion

  constructor: (@top, @bottom) ->

  setTop: (@top) ->

  setBottom: (@bottom) ->

  getTop: ->
    @top

  getBottom: ->
    @bottom

  save: ->
    @savedTop = @top
    @savedBottom = @bottom

  restore: ->
    @top = @savedTop
    @bottom = @savedBottom

