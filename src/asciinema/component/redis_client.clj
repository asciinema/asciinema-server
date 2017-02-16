(ns asciinema.component.redis-client
  (:require [asciinema.boundary.expiring-set :as exp-set]
            [clj-time.core :as t]
            [clj-time.local :as tl]
            [com.stuartsierra.component :as component]
            [taoensso.carmine :as car]))

(defrecord RedisClient [host port]
  component/Lifecycle
  (start [component]
    (if (:listener component)
      component
      (let [conn {:pool {} :spec {:host host :port port}}]
        (assoc component :conn conn))))
  (stop [component]
    (if (:conn component)
      (dissoc component :conn)
      component))

  exp-set/ExpiringSet
  (conj! [this value expires-at]
    (let [seconds (t/in-seconds (t/interval (tl/local-now) expires-at))]
      (car/wcar (:conn this) (car/setex value seconds true))))
  (contains? [this value]
    (car/as-bool (car/wcar (:conn this) (car/exists value)))))

(defn redis-client [{:keys [host port]}]
  (->RedisClient host port))
