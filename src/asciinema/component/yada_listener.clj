(ns asciinema.component.yada-listener
  (:require [bidi.vhosts :refer [vhosts-model]]
            [com.stuartsierra.component :as component]
            [yada.yada :as yada]))

(defrecord YadaListener [port server app]
  component/Lifecycle
  (start [component]
    (if server
      component
      (let [handler (vhosts-model [:* (:routes app)]) ; wrap in * vhost to make path-for work
            server (yada/listener handler {:port port})]
        (assoc component :server server))))
  (stop [component]
    (if server
      (do
        ((:close server))
        (assoc component :server nil))
      component)))

(defn yada-listener [{:keys [port app]}]
  (map->YadaListener {:port port :app app}))
