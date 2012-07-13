class AsciiIo.Worker
  constructor: (url) ->
    @webWorker = new window.Worker(url)
    @webWorker.addEventListener 'message', @onMessage

  init: (options) ->
    @webWorker.postMessage
      cmd: 'init'
      options: options

  getProxy: (objectName) ->
    new AsciiIo.WorkerProxy(@webWorker, objectName)

  onMessage: (e) =>
    if e.data.log
      console.log "log message from worker: #{e.data.log}"


class AsciiIo.WorkerProxy
  constructor: (@webWorker, @objectName) ->
    _.extend(this, Backbone.Events)
    @webWorker.addEventListener 'message', @onMessage

  onMessage: (e) =>
    if e.data.evt and e.data.src == @objectName
      @trigger e.data.evt, e.data.args...

  call: (method, args...) ->
    @webWorker.postMessage
      objectName: @objectName
      method: method
      args: args
