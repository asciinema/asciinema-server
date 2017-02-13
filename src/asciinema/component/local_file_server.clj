(ns asciinema.component.local-file-server
  (:require [asciinema.boundary
             [file-server :as file-server]
             [file-store :as file-store]]
            [ring.util.http-response :as response]))

(defrecord LocalFileServer [file-store]
  file-server/FileServer
  (serve [this path]
    (file-server/serve this path {}))
  (serve [this path {:keys [filename]}]
    (let [resp (response/ok (file-store/input-stream file-store path))]
      (if filename
        (response/header resp "Content-Disposition" (str "attachment; filename=" filename))
        resp))))

(defn local-file-server [{:keys [file-store]}]
  (->LocalFileServer file-store))
