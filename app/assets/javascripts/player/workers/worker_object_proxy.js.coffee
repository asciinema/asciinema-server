class Asciinema.WorkerObjectProxy
  constructor: (@webWorker, @objectName) ->
    _.extend(this, Backbone.Events)
    @webWorker.addEventListener 'message', @onMessage

  onMessage: (e) =>
    if e.data.evt and e.data.src == @objectName
      @trigger e.data.evt, e.data.args...

  call: (method, args...) ->
    @webWorker.postMessage
      message: 'call'
      objectName: @objectName
      method: method
      args: args
