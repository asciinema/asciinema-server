(ns asciinema.main
    (:gen-class)
    (:require [com.stuartsierra.component :as component]
              [duct.util.runtime :refer [add-shutdown-hook]]
              [duct.util.system :refer [load-system]]
              [environ.core :refer [env]]
              [clojure.java.io :as io]))

(defn -main [& args]
  (let [bindings {'http-port (Integer/parseInt (:port env "3000"))
                  'db-uri    (:database-url env)
                  's3-bucket (:s3-bucket env)
                  's3-access-key (:s3-access-key env)
                  's3-secret-key (:s3-secret-key env)}
        system   (->> (load-system [(io/resource "asciinema/system.edn")] bindings)
                      (component/start))]
    (add-shutdown-hook ::stop-system #(component/stop system))
    (println "Started HTTP server on port" (-> system :http :port)))
  @(promise))
