(ns asciinema.endpoint.asciicasts
  (:require [asciinema.boundary
             [asciicast-database :as adb]
             [executor :as executor]
             [expiring-set :as exp-set]
             [file-store :as fstore]
             [user-database :as udb]]
            [asciinema.model.asciicast :as asciicast]
            [asciinema.util.io :refer [with-tmp-dir]]
            [clj-time.core :as t]
            [clojure.java
             [io :as io]
             [shell :as shell]]
            [clojure.string :as str]
            [compojure.api.sweet :refer :all]
            [environ.core :refer [env]]
            [ring.util.http-response :as response]
            [schema.core :as s]))

(defn exception-handler [^Exception e data request]
  (throw e))

(defn a2png [in-url out-path {:keys [snapshot-at theme scale]}]
  (let [a2png-bin (:a2png-bin env "a2png/a2png.sh")
        {:keys [exit] :as result} (shell/sh a2png-bin
                                            "-t" theme
                                            "-s" (str scale)
                                            in-url
                                            out-path
                                            (str snapshot-at))]
    (when-not (zero? exit)
      (throw (ex-info "a2png error" result)))))

(def Num (s/if #(str/includes? % ".")
           Double
           s/Int))

(def Theme (apply s/enum asciicast/themes))

(def png-ttl-days 7)

(defn asciicasts-endpoint [{:keys [db file-store exp-set executor]}]
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
             (fstore/serve-file file-store path (when dl {:filename filename})))
           (response/not-found)))

    (GET "/:token.png" []
         :path-params [token :- String]
         :query-params [{time :- Num nil}
                        {theme :- Theme nil}
                        {scale :- (s/enum "1" "2") nil}]
         (if-let [asciicast (adb/get-asciicast-by-token db token)]
           (let [user (udb/get-user-by-id db (:user_id asciicast))
                 png-params (cond-> (asciicast/png-params asciicast user)
                              time (assoc :snapshot-at time)
                              theme (assoc :theme theme)
                              scale (assoc :scale (Integer/parseInt scale)))
                 png-store-path (asciicast/png-store-path asciicast png-params)]
             (if (exp-set/contains? exp-set png-store-path)
               (fstore/serve-file file-store png-store-path {})
               (executor/execute executor (fn []
                                            (with-tmp-dir [dir "asciinema-png-"]
                                              (let [json-store-path (asciicast/json-store-path asciicast)
                                                    json-local-path (str dir "/asciicast.json")
                                                    png-local-path (str dir "/asciicast.png")
                                                    expires (-> png-ttl-days t/days t/from-now)]
                                                (with-open [in (fstore/input-stream file-store json-store-path)]
                                                  (let [out (io/file json-local-path)]
                                                    (io/copy in out)))
                                                (a2png json-local-path png-local-path png-params)
                                                (fstore/put-file file-store (io/file png-local-path) png-store-path)
                                                (exp-set/conj! exp-set png-store-path expires)))
                                            (fstore/serve-file file-store png-store-path {})))))
           (response/not-found))))))
