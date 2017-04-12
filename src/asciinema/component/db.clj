(ns asciinema.component.db
  (:require [asciinema.boundary.asciicast-database :refer :all]
            [asciinema.boundary.user-database :refer :all]
            [clojure.java.jdbc :as jdbc]
            [clj-time.coerce :as timec]
            [duct.component.hikaricp :as hikaricp]))

(extend-protocol jdbc/ISQLValue
  org.joda.time.DateTime
  (sql-value [val]
    (timec/to-sql-time val)))

(extend-protocol jdbc/IResultSetReadColumn
  java.sql.Timestamp
  (result-set-read-column [x _ _]
    (timec/from-sql-time x)))

;; AsciicastDatabase

(def q-get-asciicast-by-id "SELECT * FROM asciicasts WHERE id=?")
(def q-get-asciicast-by-secret-token "SELECT * FROM asciicasts WHERE secret_token=?")
(def q-get-public-asciicast-by-id "SELECT * FROM asciicasts WHERE id=? AND private=FALSE")

(extend-protocol AsciicastDatabase
  duct.component.hikaricp.HikariCP

  (get-asciicast-by-id [{db :spec} id]
    (first (jdbc/query db [q-get-asciicast-by-id id])))

  (get-asciicast-by-token [{db :spec} token]
    (when-let [query (cond
                       (re-matches #"\d+" token)
                       [q-get-public-asciicast-by-id (Long/parseLong token)]
                       (= (count token) 25)
                       [q-get-asciicast-by-secret-token token])]
      (first (jdbc/query db query)))))

;; UserDatabase

(def q-get-user-by-id "SELECT * FROM users WHERE id=?")

(extend-protocol UserDatabase
  duct.component.hikaricp.HikariCP

  (get-user-by-id [{db :spec} id]
    (first (jdbc/query db [q-get-user-by-id id]))))

;; constructor

(def hikaricp hikaricp/hikaricp)
