(ns clojure.test.generative.tagger
  (:require [clojure.walk :as walk]))

(defn- fully-qualified
  "Qualify a name used in :tag metadata. Unqualified names are
   interpreted in the 'clojure.test.generative.generators, except
   for the fn-building symbols fn and fn*."
  [n]
  (let [ns (cond
            (#{'fn*} n) nil
            (#{'fn} n) 'clojure.core
            (namespace n) (namespace n)
            :else 'clojure.test.generative.generators)]
    (if ns
      (symbol (str ns) (name n))
      n)))
 
(defn- dequote
  "Remove the backquotes used to call out user-namespaced forms."
  [form]
  (walk/prewalk
   #(if (and (sequential? %)
             (= 2 (count %))
             (= 'quote (first %)))
      (second %)
      %)
   form))

(defn tag->gen
  "Convert tag to source code form for a test data generator."
  [arg]
  (let [form (walk/prewalk (fn [s] (if (symbol? s) (fully-qualified s) s)) (dequote arg))]
    (if (seq? form)
      (list 'fn '[] form) 
      form)))

(defn- tag-or-uniform [x]
  (if-let [[start end] (:uniform x)]
    (list 'uniform start end)
    (:tag x)))

(defn extract-arg-fns [tagged-arg-vec]
  (let []
    (vec (map #(-> % meta tag-or-uniform tag->gen eval) tagged-arg-vec))))

