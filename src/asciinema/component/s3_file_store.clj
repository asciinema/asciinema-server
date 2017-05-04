(ns asciinema.component.s3-file-store
  (:require [asciinema.boundary.file-store :as file-store]
            [aws.sdk.s3 :as s3]
            [clj-time
             [coerce :as timec]
             [core :as time]]
            [ring.util.http-response :as response]
            [ring.util.mime-type :as mime-type])
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

(defrecord S3FileStore [cred bucket path-prefix]
  file-store/FileStore

  (put-file [this file path]
    (file-store/put-file this file path nil))

  (put-file [this file path size]
    (let [path (str path-prefix path)
          content-type (mime-type/ext-mime-type path)]
      (s3/put-object cred bucket path file {:content-length size
                                            :content-type content-type})))

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
      (s3/delete-object cred bucket path)))

  (serve-file [this ctx path opts]
    (let [path (str path-prefix path)
          url (generate-presigned-url cred bucket path opts)]
      (-> (:response ctx)
          (assoc :status 302)
          (update :headers assoc "location" url)))))

(defn s3-file-store
  [{:keys [s3-cred s3-bucket path]}]
  {:pre [(some? s3-cred) (some? s3-bucket) (some? path)]}
  (->S3FileStore s3-cred s3-bucket path))
