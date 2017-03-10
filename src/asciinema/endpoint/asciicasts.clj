(ns asciinema.endpoint.asciicasts
  (:require [asciinema.boundary
             [asciicast-database :as adb]
             [executor :as executor]
             [expiring-set :as exp-set]
             [file-store :as fstore]
             [png-generator :as png]
             [user-database :as udb]]
            [asciinema.model.asciicast :as asciicast]
            [asciinema.yada :refer [not-found-model resource]]
            [clj-time.core :as t]
            [schema.core :as s]
            [yada.yada :as yada]))

(def Theme (apply s/enum asciicast/themes))

(defn- service-unavailable-response [ctx]
  (-> (:response ctx)
      (assoc :status 503)
      (update :headers assoc "retry-after" "5")))

(defn- async-response [ctx executor f]
  (or (executor/execute executor f)
      (service-unavailable-response ctx)))

(defn asciicast-file-resource [db file-store]
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

(def png-ttl-days 7)

(defn asciicast-image-resource [db file-store exp-set executor png-gen]
  (resource
   {:produces
    "image/png"

    :parameters
    {:path {:token String}
     :query {(s/optional-key :time) s/Num
             (s/optional-key :theme) Theme
             (s/optional-key :scale) (s/enum "1" "2")}}

    :properties
    (fn [ctx]
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

    :response
    (fn [ctx]
      (let [asciicast (-> ctx :properties ::asciicast)
            png-params (-> ctx :properties ::png-params)
            png-store-path (asciicast/png-store-path asciicast png-params)
            expires (-> png-ttl-days t/days t/from-now)]
        (if (exp-set/contains? exp-set png-store-path)
          (fstore/serve-file file-store ctx png-store-path {})
          (async-response ctx
                          executor
                          (fn []
                            (let [json-store-path (asciicast/json-store-path asciicast)]
                              (with-open [json-is (fstore/input-stream file-store json-store-path)
                                          png-is (png/generate png-gen json-is png-params)]
                                (fstore/put-file file-store png-is png-store-path)))
                            (exp-set/conj! exp-set png-store-path expires)
                            (fstore/serve-file file-store ctx png-store-path {}))))))}))

(defn asciicasts-endpoint [{:keys [db file-store exp-set executor png-gen]}]
  ["" [["/a/" [[[:token ".json"] (asciicast-file-resource db file-store)]
               [[:token ".png"] (asciicast-image-resource db file-store exp-set executor png-gen)]]]
       [true (yada/resource not-found-model)]]])
