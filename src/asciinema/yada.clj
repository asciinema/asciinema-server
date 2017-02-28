(ns asciinema.yada
  (:require [clojure.java.io :as io]
            [yada.yada :as yada]))

(defn not-found-response [ctx]
  (case (yada/content-type ctx)
    "text/html" (io/input-stream (io/resource "asciinema/errors/404.html"))
    "Not found"))

(defn resource [model]
  (-> model
      (update-in [:responses 404] #(or %
                                       {:produces #{"text/html" "text/plain"}
                                        :response not-found-response}))
      yada/resource))
