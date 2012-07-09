class AsciiIo.VTWorkerProxy extends AsciiIo.WorkerProxy
  feed: (data) ->
    @sendMessage 'feed', data
