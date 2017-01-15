(ns asciinema.component.s3-file-store
  (:require [asciinema.boundary.file-store :as file-store]
            [aws.sdk.s3 :as s3]))

(defrecord S3FileStore [cred bucket path-prefix]
  file-store/FileStore
  (put-file [this file path]
    (file-store/put-file this file path nil))
  (put-file [this file path size]
    (let [path (str path-prefix path)]
      (s3/put-object cred bucket path file {:content-length size})))
  (input-stream [this path]
    (let [path (str path-prefix path)]
      (:content (s3/get-object cred bucket path))))
  (move-file [this old-path new-path]
    (let [old-path (str path-prefix old-path)
          new-path (str path-prefix new-path)]
      (s3/copy-object cred bucket old-path new-path)
      (s3/delete-object cred bucket old-path)))
  (delete-file [this path]
    (let [path (str path-prefix path)]
      (s3/delete-object cred bucket path))))

(defn s3-file-store [{:keys [cred bucket path-prefix]}]
  (->S3FileStore cred bucket path-prefix))
