class Asciinema.Player extends Asciinema.AbstractPlayer

  constructor: (@options) ->
    @createWorkerProxy()
    super

  createWorkerProxy: ->
    @workerProxy = new Asciinema.WorkerProxy(window.mainWorkerPath)

  createMovie: ->
    @movie = @workerProxy.getObjectProxy 'movie'

  onModelReady: ->
    @initWorkerProxy()
    super

  initWorkerProxy: ->
    @workerProxy.init @movieOptions()
