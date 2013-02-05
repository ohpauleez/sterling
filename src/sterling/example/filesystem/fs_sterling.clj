(ns sterling.example.filesystem.fs-sterling
  (:require [sterling.alloy :as alloy]))

(def FSObject {:sig :abstract
                :parent {:lone :FSDir}})

(def FSDir {:extends :FSObject
             :contents {:set :FSObject}})

(def FSFile {:extends :FSObject})

(def root {:sig :one
           :extends :FSDir})

(def -facts
  [{:all "x: FSObject-root"
    :such-that "one x.parent"}
   {:no "d: FSDir"
    :such-that "d in d.^contents"}
   {:holds "contents = ~ parent"}])

(def -assertions
  {:one_root {:one "d: FSDir"
              :such-that "no d.parent"}})

(comment
  (alloy/alloy 'sterling.example.filesystem.fs-sterling
               :facts -facts
               :assertions -assertions
               :checks [[:one_root :for 5]])

  ;(alloy/alloy 'sterling.example.filesystem.fs-sterling
  ;             :facts -facts
  ;             :run {}
  ;             :for 3
  ;             :but {})
  )

