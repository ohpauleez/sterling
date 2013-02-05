;   Copyright (c) Rich Hickey, Stuart Halloway, and contributors.
;   All rights reserved.
;   The use and distribution terms for this software are covered by the
;   Eclipse Public License 1.0 (http://opensource.org/licenses/eclipse-1.0.php)
;   which can be found in the file epl-v10.html at the root of this distribution.
;   By using this software in any fashion, you are agreeing to be bound by
;   the terms of this license.
;   You must not remove this notice, or any other, from this software.

(ns clojure.test.generative
  (:require [clojure.test.generative.tagger :as tagger]
            [clojure.test.generative.event :as event]
            [clojure.test.generative.runner :as runner]))

(defmacro fail
  [& args]
  `(do
     (runner/failed!)
     ~(with-meta `(event/report-context :assert/fail
                                        :level :warn
                                        ~@args)
        (meta &form))))

(defmacro is
  "Assert that v is true, otherwise fail the current generative
   test (with optional msg)."
  ([v] (with-meta `(is ~v nil) (meta &form)))
  ([v msg]
     `(let [~'actual ~v ~'expected '~v]
        (if ~'actual
          (do
            (event/report :assert/pass :level :debug)
            ~'actual)
          ~(with-meta
             `(fail ~@(when msg `[:message ~msg]))
             (meta &form))))))

(defn defspec [& args]
  (throw (Exception. "clojure.test.generative/defspec has been replaced with deftestspec.
                     Please update your code.")))

(defmacro deftestspec
  "Defines a function named name that expects args. The defined
   function binds '%' to the result of calling fn-to-test with args,
   and runs validator-body forms (if any), which have access to both
   args and %. The defined function.

   Args must have type hints (i.e. :tag metdata), which are
   interpreted as instructions for generating test input
   data. Unquoted names in type hints are resolved in the
   c.t.g.generators namespace, which has generator functions for
   common Clojure data types. For example, the following argument list
   declares that 'seed' is an int, and that 'iters' is an int in the
   uniform distribution from 1 to 100:

       [^int seed ^{:tag (uniform 1 100)} iters]

   Backquoted names in an argument list are resolved in the current
   namespace, allowing arbitrary generators, e.g.

       [^{:tag `scary-word} word]

   The function c.t.g.runner/run-iter takes a var naming a test, and runs
   a single test iteration, generating inputs based on the arg type hints."
  [name fn-to-test args & validator-body]
  (when-let [missing-tags (->> (map #(list % (-> % meta :tag)) args)
                               (filter (fn [[_ tag]] (nil? tag)))
                               seq)]
    (throw (IllegalArgumentException. (str "Missing tags for " (seq (map first missing-tags)) " in " name))))
  `(defn ~(with-meta name (assoc (meta name)
                            ::type :defspec
                            ::arg-fns (into [] (map #(-> % meta :tag tagger/tag->gen eval)  args))))
     ~(into [] (map (fn [a#] (with-meta a# (dissoc (meta a#) :tag))) args))
     (let [~'% (apply ~fn-to-test ~args)]
       ~@validator-body
       ~'%)))

