(defproject sterling "0.1.0-SNAPSHOT"
  :description "Unifying core.contracts, test.generative, and Alloy"
  :url "http://example.com/FIXME"
  :license {:name "Eclipse Public License"
            :url "http://www.eclipse.org/legal/epl-v10.html"}
  :dependencies [[org.clojure/clojure "1.4.0"]
                 [org.clojure/core.unify "0.5.3"] ;core.contracts
                 [org.clojure/tools.namespace "0.2.2"]
                 [typed "0.1.6"]]
  :dev-dependencies [;[criterium "0.3.0"]
                     [lein-marginalia "0.7.1"]]
  :resource-paths  ["resources/alloy4.2.jar" "resources"])

