(ns asciinema.yada
  (:require [clojure.java.io :as io]
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

(defn resource [model]
  (-> model
      (update-in [:responses 404] #(or % not-found-model))
      yada/resource))
