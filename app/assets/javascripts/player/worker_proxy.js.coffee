class AsciiIo.WorkerProxy
  constructor: (@worker, @objectName) ->
    _.extend(this, Backbone.Events)
    @worker.onmessage = @onMessage

  onMessage: (e) =>
    if e.data.log
      console.log "log message from #{@objectName}: #{e.data.log}"
    else if e.data.evt
      if e.data.src == @objectName
        # console.log e.data.evt
        # console.log e.data.arg1
        @trigger e.data.evt, e.data.arg1

  sendMessage: (msg, arg1, arg2, arg3) ->
    @worker.postMessage
      objectName: @objectName
      message: msg
      args: [arg1, arg2, arg3]
