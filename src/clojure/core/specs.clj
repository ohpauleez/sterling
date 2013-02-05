(ns clojure.core.specs
  (:require [clojure.test.generative.generators :as gen]
            [typed.core :refer [ann ann-form]]))

(defn- extract-spec-args
  "Specs have optional docstrings.
  This function processes the potential arguments to a spec
  and returns the correct doc string, argment vector, and spec extension map"
  [arg-vec kw-specs]
  (if-let [spec-doc (when (string? arg-vec) arg-vec)]
    (if (odd? (count kw-specs))
      [spec-doc (first kw-specs) (apply hash-map (rest kw-specs))]
      (throw (IllegalArgumentException. "Raw specification needs an argument vector, after the doc string")))
    ["" arg-vec (apply hash-map kw-specs)]))

(defn between? [start eq1 a-var eq2 end]
  (and (eq1 start a-var) (eq2 a-var end)))

(defn enforced-constraint [arg]
  (let [meta-map (meta arg)]
    (when-let [[start end] (and (:enforced meta-map)
                                (:uniform meta-map))]
      [(str "The input must be between " start "-" (dec end)) :pre `(between? ~start <= ~arg < ~end)])))

(defn extract-enforced-args
  "Given the arg vector to a spec,
  extract the constraints from enforced uniform tags on vars"
  [arg-vec]
  (keep enforced-constraint arg-vec))

(defn adorn-tag [arg]
  (let [meta-map (meta arg)]
    (if (:tag meta-map)
      arg
      (with-meta arg (assoc meta-map :tag (if-let [[lo hi] (:uniform meta-map)]
                                            `(gen/uniform ~lo ~hi) 
                                            ;Object
                                            nil))))))

(defn ensure-tags
  "Given the arg vector to a spec,
  produce a new arg-vec where all the vars have :tag metadata attached."
  [arg-vec]
  (vec (map adorn-tag arg-vec)))

(defn divide-pre-post
  "'[odd? pos? => int?]
     =>
   {:pre (odd? pos?) :post (int?)}
  "
  [cnstr]
  (if (vector? cnstr)
    (let [[L M R] (partition-by #{'=>} cnstr)]
      {:pre  (when (not= L '(=>)) (first L))
       :post (if (= L '(=>)) (first M) (first R))})
    cnstr))

(defn enmap-constraint [c-vec]
  (if (some #{:pre :post} c-vec)
    (into {:doc (first c-vec)} (apply hash-map (rest c-vec)))
    (into {:doc (first c-vec)} (divide-pre-post (vec (rest c-vec))))))

(defn normalize-constraints
  "Given the final constraints vec of a spec,
  Normalize all the single constraint vectors to be maps in the format {:doc :pre :post}
  Optionally, you can call with additional constraint vecs,
  which will be merged via `into` and normalized"
  ([constraints-vec]
   (vec (map enmap-constraint constraints-vec)))
  ([constraints-vec & additional-vecs]
   (normalize-constraints (reduce into constraints-vec additional-vecs))))

(defn raw-spec
  "This function allows raw access to spec generation.
  No checks or validations are performed against the args.
  `spec` will return a map, the specification, for a function.
  This map is the entry-point for external systems:
   - test.generative
   - core.contracts
   - external systems (Alloy, typed clojure, documentation generation etc)
  
  Optionally, you can specify a doc string for the spec:
   (raw-spec a-fn 'this is the doc string' [^long x] ...)
  vs:
   (raw-spec a-fn [^long x] ...)"
  [fn-to-test arg-vec & kw-specs]
  (let [[spec-doc arg-vec ext-map] (extract-spec-args arg-vec kw-specs)
        additional-constraints (extract-enforced-args arg-vec)]
    {::type :defspec
     ::f fn-to-test
     ::args (ensure-tags arg-vec)
     ::ext (update-in ext-map [:constraints] normalize-constraints additional-constraints)
     ::doc spec-doc}))

(defmacro defspec
  "Top-level macro to define spec maps and `def` them."
  [name & raw-spec-args]
  (let [spec-map (apply raw-spec raw-spec-args)]
    (when-let [missing-tags (->> (map #(list % (-> % meta :tag)) (::args spec-map))
                                 (filter (fn [[_ tag]] (nil? tag)))
                                 seq)]
      (throw (IllegalArgumentException. (str "Missing tags for " (seq (map first missing-tags)) " in " name))))
    `(def ~name '~spec-map)))


(defn extract-conditions [constraints-vec condition-kw]
  (vec (keep condition-kw constraints-vec)))

;; TODO: All decorate-fn methods should update the doc-string as well.  This should be an aux fn
(defmulti decorate-fn
  ""
  (fn [decorate-kw spec-map f]
    decorate-kw))

(defmethod decorate-fn :constraints [_ spec-map f]
  (if-let [constraints (get-in spec-map [::ext :constraints])]
    (let [pre-conditions (extract-conditions constraints :pre)
          post-conditions (extract-conditions constraints :post)]
      ;; TODO: make this a real decorator; one that can handle var-args; Can c.c.contracts handle var args? because of the root-binding?
      (eval (list `fn (::args spec-map) {:pre pre-conditions :post post-conditions} (list* f (::args spec-map)))))
    f))

(defmethod decorate-fn :typed [_ spec-map f]
  (if-let [type-vec (get-in spec-map [::ext :typed])]
    (do (eval (list `ann-form f (list* 'Fn type-vec)))
      f)
    f))

;; TODO: Make this a proper, strong, type annotation
(ann fn-with [Any -> Any])
(defn fn-with
  "Given a spec map,
  produce a function that is decorated with the spec'd keywords
  TODO: rewrite this doc string"
  [spec-map & kw-decs]
  (let [ret (reduce (fn [f decorate-kw] (decorate-fn decorate-kw spec-map f)) (::f spec-map) kw-decs)]
    (if (symbol? ret)
      (resolve ret)
      ret)))

;; TODO: Add the functionality for the example usage.
;; It should 
(defn example
  "Given the var of a spec-map,
  produce a map that illustrates ideal usage of the spec'd function
  This is very similar to `run-iter` of test.generative"
  [spec-map-var]
  (clojure.test.generative.runner/run-example spec-map-var))

(defn example-str
  "Given the var of a spec-map
  produce a string that illustrates ideal usage of the spec'd function.
  The string's format will follow The Joy of Clojure's REPL format."
  [spec-map-var]
  (let [example-map (example spec-map-var)]
    (str (:example example-map) "  =>  " (:result example-map))))

