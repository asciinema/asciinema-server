(ns asciinema.endpoint.asciicasts
  (:require [asciinema.boundary
             [asciicast-database :as adb]
             [file-server :as fserver]]
            [asciinema.model.asciicast :as asciicast]
            [compojure.api.sweet :refer :all]
            [ring.util.http-response :as response]
            [schema.core :as s]))

(defn exception-handler [^Exception e data request]
  (throw e))

(defn asciicasts-endpoint [{:keys [db file-server]}]
  (api
   {:exceptions {:handlers {:compojure.api.exception/default exception-handler}}}
   (context
    "/a" []
    (GET "/:token.json" []
         :path-params [token :- String]
         :query-params [{dl :- s/Bool false}]
         (if-let [asciicast (adb/get-asciicast-by-token db token)]
           (let [path (asciicast/json-store-path asciicast)
                 filename (str "asciicast-" (:id asciicast) ".json")]
             (fserver/serve file-server path (when dl {:filename filename})))
           (response/not-found))))))
