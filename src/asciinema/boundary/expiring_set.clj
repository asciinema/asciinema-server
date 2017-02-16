(ns asciinema.boundary.expiring-set
  (:refer-clojure :exclude [conj! contains?]))

(defprotocol ExpiringSet
  (conj! [this value expires-at])
  (contains? [this value]))
