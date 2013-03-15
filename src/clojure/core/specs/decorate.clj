(ns clojure.core.specs.decorate
  "Decorating and generating functions/records from specifications // spec maps"
  (:require [clojure.core.typed :refer [ann ann-form]]))

(defn extract-conditions [constraints-vec condition-kw]
  (vec (keep condition-kw constraints-vec)))

;; TODO: All decorate-fn methods should update the doc-string as well.  This should be an aux fn
(defmulti decorate-fn
  ""
  (fn [decorate-kw spec-map f]
    decorate-kw))

(defmethod decorate-fn :constraints [_ spec-map f]
  (if-let [constraints (get-in spec-map [:clojure.core.specs/ext :constraints])]
    (let [pre-conditions (extract-conditions constraints :pre)
          post-conditions (extract-conditions constraints :post)]
      ;; TODO: make this a real decorator; one that can handle var-args; Can c.c.contracts handle var args? because of the root-binding?
      (eval (list `fn (:clojure.core.specs/args spec-map) {:pre pre-conditions :post post-conditions} (list* f (:clojure.core.specs/args spec-map)))))
    f))

(defmethod decorate-fn :typed [_ spec-map f]
  (if-let [type-vec (get-in spec-map [:clojure.core.specs/ext :typed])]
    (do (eval (list `ann-form f (list* 'Fn type-vec)))
      f)
    f))

;; TODO: Make this a proper, strong, type annotation
(ann fn-with [(HMap) clojure.lang.Keyword * -> (Fn [Any -> Any])])
(defn fn-with
  "Given a spec map,
  produce a function that is decorated with the spec'd keywords
  TODO: rewrite this doc string"
  [spec-map & kw-decs]
  (let [ret (reduce (fn [f decorate-kw] (decorate-fn decorate-kw spec-map f)) (:clojure.core.specs/f spec-map) kw-decs)]
    (if (symbol? ret)
      (resolve ret)
      ret)))
 
