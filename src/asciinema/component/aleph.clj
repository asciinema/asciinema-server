(ns asciinema.component.aleph
  (:require [com.stuartsierra.component :as component]
            [aleph.http :refer [start-server]]))

(defrecord WebServer [port server app]
  component/Lifecycle
  (start [component]
    (let [handler (:handler app)
          server (start-server handler {:port port :join? false})]
      (assoc component :server server)))
  (stop [component]
    (when server
      (.close server)
      component)))

(defn aleph-server [{:keys [port app]}]
  (map->WebServer {:port port :app app}))
