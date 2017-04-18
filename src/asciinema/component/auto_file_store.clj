(ns asciinema.component.auto-file-store
  (:require [asciinema.component.local-file-store :refer [local-file-store]]
            [asciinema.component.s3-file-store :refer [s3-file-store]]))

(defn auto-file-store [config]
  (if (:s3-bucket config)
    (s3-file-store config)
    (local-file-store config)))
