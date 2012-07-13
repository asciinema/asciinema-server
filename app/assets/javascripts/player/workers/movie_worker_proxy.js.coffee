class AsciiIo.MovieWorkerProxy extends AsciiIo.WorkerProxy
  togglePlay: ->
    @sendMessage 'togglePlay'
