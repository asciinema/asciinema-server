class AsciiIo.Player extends AsciiIo.AbstractPlayer

  constructor: (@options) ->
    @createWorkerProxy()
    super

  createWorkerProxy: ->
    @workerProxy = new AsciiIo.WorkerProxy(window.mainWorkerPath)

  createVT: ->
    @vt = @workerProxy.getObjectProxy 'vt'

  createMovie: ->
    @movie = @workerProxy.getObjectProxy 'movie'

  onModelReady: ->
    @initWorkerProxy()
    super

  initWorkerProxy: ->
    @workerProxy.init @movieOptions()
