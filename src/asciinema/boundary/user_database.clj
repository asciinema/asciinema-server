(ns asciinema.boundary.user-database)

(defprotocol UserDatabase
  (get-user-by-id [this id]))
