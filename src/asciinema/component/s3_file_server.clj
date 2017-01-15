(ns asciinema.component.s3-file-server
  (:require [asciinema.boundary.file-server :as file-server]
            [aws.sdk.s3 :as s3]
            [ring.util.http-response :as response]))

;; TODO support custom expiry date (it's 1 day now)

(defrecord S3FileServer [cred bucket path-prefix]
  file-server/FileServer
  (serve [this path]
    (let [path (str path-prefix path)]
      (response/found (s3/generate-presigned-url cred bucket path)))))

(defn s3-file-server [{:keys [cred bucket path-prefix]}]
  (->S3FileServer cred bucket path-prefix))
