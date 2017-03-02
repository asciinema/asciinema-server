(ns asciinema.yada
  (:require [clojure.java.io :as io]
            [taoensso.timbre :as log]
            [yada.status :as status]
            [yada.yada :as yada]))

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

(defn logger [ctx]
  (when-let [error (:error ctx)]
    (when (not= (-> ctx :response :status) 404)
      (log/error error))))

(defn resource [model]
  (let [error-statuses (set (concat (range 400 404) (range 405 600) ))]
    (-> model
        (assoc :logger logger)
        (update-in [:responses 404] #(or % not-found-model))
        (update-in [:responses error-statuses] #(or % {:produces #{"text/html" "text/plain"}
                                                       :response error-response}))
        yada/resource)))
