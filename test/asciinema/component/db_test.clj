(ns asciinema.component.db-test
  (:require [clojure.test :refer :all]
            [clojure.java.jdbc :as jdbc]
            [clj-time.local :as timel]
            [com.stuartsierra.component :as component]
            [asciinema.component.db :as db]
            [asciinema.boundary.asciicast-database :as adb]))

(defmacro with-db-component [component-var & body]
  `(let [component# (-> (db/hikaricp {:uri "jdbc:postgresql://localhost:15432/asciinema_test?user=vagrant"})
                        component/start)]
     (try
       (jdbc/with-db-transaction [db# (:spec component#)]
         (let [~component-var (assoc component# :spec db#)]
           (jdbc/db-set-rollback-only! db#)
           ~@body))
       (finally
         (component/stop component#)))))

(defn insert-asciicast
  ([db] (insert-asciicast db {}))
  ([db attrs]
   (first (jdbc/insert! db :asciicasts (merge {:duration 10.0
                                               :terminal_columns 80
                                               :terminal_lines 24
                                               :created_at (timel/local-now)
                                               :updated_at (timel/local-now)
                                               :version 1
                                               :secret_token "abcdeabcdeabcdeabcdeabcde"}
                                              attrs)))))

(deftest get-asciicast-by-id-test
  (testing "for existing asciicast"
    (with-db-component db
      (let [asciicast (insert-asciicast (:spec db))]
        (is (map? (adb/get-asciicast-by-id db (:id asciicast)))))))
  (testing "for non-existing asciicast"
    (with-db-component db
      (is (nil? (adb/get-asciicast-by-id db 1))))))

(deftest get-asciicast-by-token-test
  (testing "for existing public asciicast"
    (with-db-component db
      (let [asciicast (insert-asciicast (:spec db) {:private false})]
        (is (map? (adb/get-asciicast-by-token db (:secret_token asciicast))))
        (is (map? (adb/get-asciicast-by-token db (-> asciicast :id str)))))))
  (testing "for existing private asciicast"
    (with-db-component db
      (let [asciicast (insert-asciicast (:spec db) {:private true})]
        (is (map? (adb/get-asciicast-by-token db (:secret_token asciicast))))
        (is (nil? (adb/get-asciicast-by-token db (-> asciicast :id str)))))))
  (testing "for non-existing asciicast"
    (with-db-component db
      (is (nil? (adb/get-asciicast-by-token db "1"))))))
