(ns dev
  (:refer-clojure :exclude [test])
  (:require [clojure.repl :refer :all]
            [clojure.pprint :refer [pprint]]
            [clojure.tools.namespace.repl :refer [refresh]]
            [clojure.java.io :as io]
            [com.stuartsierra.component :as component]
            [duct.generate :as gen]
            [duct.util.repl :refer [setup test cljs-repl migrate rollback]]
            [duct.util.system :refer [load-system]]
            [environ.core :refer [env]]
            [reloaded.repl :refer [system init start stop go reset]]
            [asciinema.boundary.file-store :as file-store]
            [asciinema.boundary.asciicast-database :as asciicast-database]
            [asciinema.component.local-file-store :refer [->LocalFileStore]]
            [asciinema.component.s3-file-store :refer [->S3FileStore]]))

(def default-db-uri "jdbc:postgresql://localhost/asciinema_development?user=asciinema")

(defn new-system []
  (let [bindings {'http-port (Integer/parseInt (:port env "4000"))
                  'db-uri (:database-url env default-db-uri)
                  's3-bucket (:s3-bucket env)
                  's3-access-key (:s3-access-key env)
                  's3-secret-key (:s3-secret-key env)}]
    (load-system (keep io/resource ["asciinema/system.edn" "dev.edn" "local.edn"]) bindings)))

(when (io/resource "local.clj")
  (load "local"))

(gen/set-ns-prefix 'asciinema)

(reloaded.repl/set-init! new-system)
