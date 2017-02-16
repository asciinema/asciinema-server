(ns asciinema.util.io
  (:require [clojure.java.shell :as shell])
  (:import java.nio.file.Files
           java.nio.file.attribute.FileAttribute))

(defn create-tmp-dir [prefix]
  (let [dir (Files/createTempDirectory prefix (into-array FileAttribute []))]
    (.toFile dir)))

(defmacro with-tmp-dir [[sym prefix] & body]
  `(let [~sym (create-tmp-dir ~prefix)]
     (try
       ~@body
       (finally
         (shell/sh "rm" "-rf" (.getPath ~sym))))))
