(ns asciinema.endpoint.asciicasts
  (:require [asciinema.boundary
             [asciicast-database :as adb]
             [executor :as executor]
             [expiring-set :as exp-set]
             [file-store :as fstore]
             [user-database :as udb]]
            [asciinema.model.asciicast :as asciicast]
            [asciinema.util.io :refer [with-tmp-dir]]
            [asciinema.yada :refer [resource not-found-model]]
            [clj-time.core :as t]
            [clojure.java
             [io :as io]
             [shell :as shell]]
            [environ.core :refer [env]]
            [schema.core :as s]
            [yada.yada :as yada]))

(def Theme (apply s/enum asciicast/themes))

(def png-ttl-days 7)

(defn- a2png [in-url out-path {:keys [snapshot-at theme scale]}]
  (let [a2png-bin (:a2png-bin env "a2png/a2png.sh")
        {:keys [exit] :as result} (shell/sh a2png-bin
                                            "-t" theme
                                            "-s" (str scale)
                                            in-url
                                            out-path
                                            (str snapshot-at))]
    (when-not (zero? exit)
      (throw (ex-info "a2png error" result)))))

(defn- generate-png [file-store exp-set asciicast png-params png-store-path]
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
      (exp-set/conj! exp-set png-store-path expires))))

(defn- service-unavailable-response [ctx]
  (-> (:response ctx)
      (assoc :status 503)
      (update :headers assoc "retry-after" "5")))

(defn- async-response [ctx executor f]
  (or (executor/execute executor f)
      (service-unavailable-response ctx)))

(defn asciicast-json-resource [db file-store]
  (resource
   {:produces "application/json"
    :parameters {:path {:token String}
                 :query {(s/optional-key :dl) s/Bool}}
    :properties (fn [ctx]
                  (if-let [asciicast (adb/get-asciicast-by-token db (-> ctx :parameters :path :token))]
                    {::asciicast asciicast}
                    {:exists? false}))
    :response (fn [ctx]
                (let [asciicast (-> ctx :properties ::asciicast)
                      dl (-> ctx :parameters :query :dl)
                      path (asciicast/json-store-path asciicast)
                      filename (str "asciicast-" (:id asciicast) ".json")]
                  (fstore/serve-file file-store ctx path (when dl {:filename filename}))))}))

(defn asciicast-png-resource [db file-store exp-set executor]
  (resource
   {:produces "image/png"
    :parameters {:path {:token String}
                 :query {(s/optional-key :time) s/Num
                         (s/optional-key :theme) Theme
                         (s/optional-key :scale) (s/enum "1" "2")}}
    :properties (fn [ctx]
                  (if-let [asciicast (adb/get-asciicast-by-token db (-> ctx :parameters :path :token))]
                    (let [user (udb/get-user-by-id db (:user_id asciicast))
                          {:keys [time theme scale]} (-> ctx :parameters :query)
                          png-params (cond-> (asciicast/png-params asciicast user)
                                       time (assoc :snapshot-at time)
                                       theme (assoc :theme theme)
                                       scale (assoc :scale (Integer/parseInt scale)))]
                      {:version (asciicast/png-version asciicast png-params)
                       ::asciicast asciicast
                       ::png-params png-params})
                    {:exists? false}))
    :response (fn [ctx]
                (let [asciicast (-> ctx :properties ::asciicast)
                      png-params (-> ctx :properties ::png-params)
                      png-store-path (asciicast/png-store-path asciicast png-params)]
                  (if (exp-set/contains? exp-set png-store-path)
                    (fstore/serve-file file-store ctx png-store-path {})
                    (async-response ctx executor (fn []
                                                   (generate-png file-store exp-set asciicast png-params png-store-path)
                                                   (fstore/serve-file file-store ctx png-store-path {}))))))}))

(defn asciicasts-endpoint [{:keys [db file-store exp-set executor]}]
  ["" [["/a/" [[[:token ".json"] (asciicast-json-resource db file-store)]
               [[:token ".png"] (asciicast-png-resource db file-store exp-set executor)]]]
       [true (yada/resource not-found-model)]]])
