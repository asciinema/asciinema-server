(ns asciinema.component.fixed-thread-executor
  (:require [aleph.flow :as flow]
            [asciinema.boundary.executor :as executor]
            [com.stuartsierra.component :as component]
            [manifold.deferred :as d])
  (:import [java.util.concurrent
            ExecutorService
            RejectedExecutionException
            TimeUnit]))

(defrecord FixedThreadExecutor [threads queue-length]
  executor/Executor
  (execute [{:keys [^ExecutorService executor]} f]
    (try
      (let [result (d/deferred)
            f (fn []
                (try
                  (d/success! result (f))
                  (catch Exception e
                    (d/error! result e))))]
        (.execute executor f)
        result)
      (catch RejectedExecutionException _
        nil)))

  component/Lifecycle
  (start [{:keys [threads queue-length] :as component}]
    (let [executor (flow/fixed-thread-executor threads {:onto? false
                                                        :initial-thread-count threads
                                                        :queue-length queue-length})]
      (assoc component :executor executor)))
  (stop [{:keys [^ExecutorService executor] :as component}]
    (.shutdown executor)
    (when-not (.awaitTermination executor 1000 TimeUnit/MILLISECONDS)
      (.shutdownNow executor))
    (assoc component :executor nil)))

(defn fixed-thread-executor [{:keys [threads queue-length]}]
  (->FixedThreadExecutor threads queue-length))
