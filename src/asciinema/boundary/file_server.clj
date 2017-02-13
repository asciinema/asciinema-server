(ns asciinema.boundary.file-server)

(defprotocol FileServer
  (serve [this path] [this path opts]))
