class AsciiIo.DataUnpacker
  unpack: (base64BzippedData, callback) ->
    data = atob base64BzippedData

    if data[0] == 'B' and data[1] == 'Z'
      if window.Worker
        worker = new Worker(window.unpackWorkerPath)
        worker.onmessage = (event) => callback event.data
        worker.postMessage data
      else
        data = ArchUtils.bz2.decode data
        callback data
    else
      callback data
