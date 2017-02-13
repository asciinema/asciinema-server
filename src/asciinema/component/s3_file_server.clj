(ns asciinema.component.s3-file-server
  (:require [asciinema.boundary.file-server :as file-server]
            [clj-time
             [coerce :as timec]
             [core :as time]]
            [ring.util.http-response :as response])
  (:import com.amazonaws.auth.BasicAWSCredentials
           com.amazonaws.services.s3.AmazonS3Client
           [com.amazonaws.services.s3.model GeneratePresignedUrlRequest ResponseHeaderOverrides]))

(defn- s3-client* [cred]
  (let [credentials (BasicAWSCredentials. (:access-key cred) (:secret-key cred))]
    (AmazonS3Client. credentials)))

(def ^:private s3-client (memoize s3-client*))

(defn- generate-presigned-url [cred bucket path {:keys [expires filename]
                                                 :or {expires (-> 1 time/days time/from-now)}}]
  (let [client (s3-client cred)
        request (GeneratePresignedUrlRequest. bucket path)]
    (.setExpiration request (timec/to-date expires))
    (when filename
      (let [header-overrides (doto (ResponseHeaderOverrides.)
                               (.setContentDisposition (str "attachment; filename=" filename)))]
        (.setResponseHeaders request header-overrides)))
    (.toString (.generatePresignedUrl client request))))

(defrecord S3FileServer [cred bucket path-prefix]
  file-server/FileServer
  (serve [this path]
    (file-server/serve this path {}))
  (serve [this path opts]
    (let [path (str path-prefix path)]
      (response/found (generate-presigned-url cred bucket path opts)))))

(defn s3-file-server [{:keys [cred bucket path-prefix]}]
  (->S3FileServer cred bucket path-prefix))
