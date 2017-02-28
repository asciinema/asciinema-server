(ns asciinema.boundary.file-store)

(defprotocol FileStore
  (put-file [this file path] [this file path size])
  (input-stream [this path])
  (move-file [this old-path new-path])
  (delete-file [this path])
  (serve-file [this ctx path opts]))
