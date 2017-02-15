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
            [reloaded.repl :refer [system init start stop go reset]]
            [asciinema.boundary.file-store :as file-store]
            [asciinema.boundary.asciicast-database :as asciicast-database]
            [asciinema.component.local-file-store :refer [->LocalFileStore]]
            [asciinema.component.s3-file-store :refer [->S3FileStore]]))

(defn new-system []
  (load-system (keep io/resource ["asciinema/system.edn" "dev.edn" "local.edn"])))

(when (io/resource "local.clj")
  (load "local"))

(gen/set-ns-prefix 'asciinema)

(reloaded.repl/set-init! new-system)
