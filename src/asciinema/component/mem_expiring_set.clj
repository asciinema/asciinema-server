(ns asciinema.component.mem-expiring-set
  (:require [asciinema.boundary.expiring-set :as exp-set]))

(defrecord MemExpiringSet [store]
  exp-set/ExpiringSet

  (conj! [this value _expires-at]
    (swap! store conj value))

  (contains? [this value]
    (contains? @store value)))

(defn mem-expiring-set [{:keys [store]}]
  (->MemExpiringSet (or store (atom #{}))))
