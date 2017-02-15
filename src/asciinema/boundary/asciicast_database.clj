(ns asciinema.boundary.asciicast-database)

(defprotocol AsciicastDatabase
  (get-asciicast-by-id [this id])
  (get-asciicast-by-token [this token]))
