(ns asciinema.yada
  (:require [clojure.java.io :as io]
            [taoensso.timbre :as log]
            [yada.status :as status]
            [yada.yada :as yada]))

(def ^:dynamic *exception-notifier* nil)

(def not-found-model
  {:produces
   #{"text/html" "text/plain"}
   :response
   (fn [ctx]
     (assoc (:response ctx)
            :status 404
            :body (case (yada/content-type ctx)
                    "text/html" (io/input-stream (io/resource "asciinema/errors/404.html"))
                    "Not found")))})

(defn error-response [ctx]
  (let [status (-> ctx :response :status)
        status-name (get-in status/status [status :name])]
    (case (yada/content-type ctx)
      "text/html" (str "<html><body><h1>" status-name "</h1></body></html>")
      status-name)))

(defn create-logger []
  (let [notifier *exception-notifier*]
    (fn [ctx]
      (when-let [error (:error ctx)]
        (let [status (-> ctx :response :status)]
          (when (not= status 404)
            (log/error error))
          (when (and (= status 500) notifier)
            (let [ex (or (-> error ex-data :error) error)]
              (notifier ex (:request ctx))))))
      ctx)))

(defn resource [model]
  (let [error-statuses (set (concat (range 400 404) (range 405 600) ))]
    (-> model
        (assoc :logger (create-logger))
        (update-in [:responses 404] #(or % not-found-model))
        (update-in [:responses error-statuses] #(or % {:produces #{"text/html" "text/plain"}
                                                       :response error-response}))
        yada/resource)))
