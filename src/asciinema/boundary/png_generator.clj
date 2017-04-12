(ns asciinema.boundary.png-generator)

(defprotocol PngGenerator
  (generate [this json-is png-params]))
