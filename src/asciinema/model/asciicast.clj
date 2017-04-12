(ns asciinema.model.asciicast
  (:require [pandect.algo.sha1 :as sha1]
            [clojure.string :as str]))

(defn json-store-path [{:keys [id file stdout_frames]}]
  (cond
    file (str "asciicast/file/" id "/" file)
    stdout_frames (str "asciicast/stdout_frames/" id "/" stdout_frames)))

(def themes #{"asciinema" "tango" "solarized-dark" "solarized-light" "monokai"})
(def default-theme "asciinema")

(defn theme-name [asciicast user]
  (or (:theme_name asciicast)
      (:theme_name user)
      default-theme))

(defn snapshot-at [{:keys [snapshot_at duration]}]
  (or snapshot_at (/ duration 2.0)))

(def default-png-scale 2)

(defn png-params [asciicast user]
  {:snapshot-at (snapshot-at asciicast)
   :theme (theme-name asciicast user)
   :scale default-png-scale})

(defn png-version [asciicast params]
  (let [attrs (assoc params :id (:id asciicast))]
    (->> attrs
         (map (fn [[k v]] (str (name k) "=" v)))
         (str/join "/")
         (sha1/sha1))))

(defn png-store-path [asciicast params]
  (let [ver (png-version asciicast params)
        png-filename (str ver ".png")]
    (str "png/" (:id asciicast) "/" png-filename)))
