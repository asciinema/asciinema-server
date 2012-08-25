class AsciiIo.DataUnpacker
  unpack: (base64BzippedData, callback) ->
    bzippedData = atob base64BzippedData

    if window.Worker
      worker = new Worker(window.unpackWorkerPath)
      worker.onmessage = (event) => callback event.data
      worker.postMessage bzippedData
    else
      data = ArchUtils.bz2.decode bzippedData
      callback data
