(ns asciinema.boundary.executor)

(defprotocol Executor
  (execute [this f]))
