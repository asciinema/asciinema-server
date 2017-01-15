(ns asciinema.component.local-file-server
  (:require [asciinema.boundary.file-server :as file-server]
            [asciinema.boundary.file-store :as file-store]
            [ring.util.http-response :as response]))

(defrecord LocalFileServer [file-store]
  file-server/FileServer
  (serve [this path]
    (response/ok (file-store/input-stream file-store path))))

(defn local-file-server [{:keys [file-store]}]
  (->LocalFileServer file-store))
