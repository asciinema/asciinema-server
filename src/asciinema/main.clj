(ns asciinema.main
    (:gen-class)
    (:require [asciinema.yada :as y]
              [clj-bugsnag.core :as bugsnag]
              [com.stuartsierra.component :as component]
              [duct.util.runtime :refer [add-shutdown-hook]]
              [duct.util.system :refer [load-system]]
              [environ.core :refer [env]]
              [clojure.java.io :as io]))

(defn- request-context [req]
  (str (-> req (get :request-method :unknown) name .toUpperCase)
       " "
       (:uri req)))

(defn- create-exception-notifier []
  (when-let [key (:bugsnag-key env)]
    (let [environment (:env-name env "production")
          version (:git-sha env)]
      (fn [ex req]
        (bugsnag/notify ex {:api-key key
                            :environment environment
                            :project-ns "asciinema"
                            :version version
                            :context (request-context req)
                            :meta {:request (dissoc req :body)}})))))

(defn -main [& args]
  (binding [y/*exception-notifier* (create-exception-notifier)]
    (let [bindings {'http-port (Integer/parseInt (:port env "3000"))
                    'db-uri (:database-url env)
                    's3-bucket (:s3-bucket env)
                    's3-access-key (:s3-access-key env)
                    's3-secret-key (:s3-secret-key env)
                    'redis-host (:redis-host env "localhost")
                    'redis-port (Integer/parseInt (:redis-port env "6379"))}
          system (->> (load-system [(io/resource "asciinema/system.edn")] bindings)
                      (component/start))]
      (add-shutdown-hook ::stop-system #(component/stop system))
      (println "Started HTTP server on port" (-> system :http :port))))
  @(promise))
