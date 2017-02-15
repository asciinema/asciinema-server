(ns asciinema.model.asciicast)

(defn json-store-path [{:keys [id file stdout_frames]}]
  (cond
    file (str "asciicast/file/" id "/" file)
    stdout_frames (str "asciicast/stdout_frames/" id "/" stdout_frames)))

(def default-theme "asciinema")

(defn theme-name [asciicast user]
  (or (:theme_name asciicast)
      (:theme_name user)
      default-theme))
