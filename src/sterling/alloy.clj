(ns sterling.alloy
  "A Clojure itnerface for interacting with Alloy"
  (:require [clojure.string :as cstr])
  (:import (java.io File)
           (edu.mit.csail.sdg.alloy4 A4Reporter
                                     Err ErrorWarning)
           (edu.mit.csail.sdg.alloy4compiler.ast Command Module)
           (edu.mit.csail.sdg.alloy4compiler.parser CompUtil)
           (edu.mit.csail.sdg.alloy4compiler.translator A4Options A4Options$SatSolver
                                                        A4Solution
                                                        TranslateAlloyToKodkod)
           #_(edu.mit.csail.sdg.alloy4viz VizGUI)))

;; Overview
;; --------
;;
;; The interface to Alloy is modeled around Clojure data, mainly maps.
;; All signatures, facts, assertions, checks - are captured as Clojure maps.
;; For more information on the syntax of those pieces, please see the README.

(defn extract-alloy-signatures
  "Given the namespace public vars of a file representing an Alloy Specification,
  extract all the necessary signatures, but not the facts, assertions, or checks.
  Produce a map representing the possible Alloy signatures within the file."
  [ns-public-map]
  (let [alloy-syms (map symbol (remove #(.startsWith (name %) "-") (keys ns-public-map)))
        alloy-map (select-keys ns-public-map alloy-syms)]
    (apply hash-map (flatten (map (fn [[k v]] [(keyword k) (var-get v)]) alloy-map)))))

(defn stringify-attr
  "Given a Signature's attribute entry in the alloy/Sterling signature map,
  correctly stringify the attr and all possible sub-attributes.
  For example:
    [:lone :FSDir] => 'lone: FSDir \n'"
  [attr-entry]
  (let [[k v] attr-entry]
    (str (name k) ": " (if (map? v)
                          (cstr/replace (apply stringify-attr v) ":" "")
                         (name v)) " \n")))

(defn- stringify-map-entry
  [[k v]]
  (str (name k) " " v))

(defn stringify-map
  "Flatten a map to a single string of it's keys (as flat strs; no colons) and values"
  [a-map]
  (reduce #(str %1 (stringify-map-entry %2)) "" a-map))

(defn generate-sig
  "Generate the Alloy signature string for a given Sterling Signature map"
  [sig-name sig-map]
  (let [sig-str (str (when (:sig sig-map) (name (:sig sig-map))) " sig " (name sig-name)
                     " " (when (:extends sig-map)
                           (str "extends " (name (:extends sig-map)))) " { ")
        attr-map (apply dissoc sig-map [:sig :extends :sterling-alloy])]
    (str sig-str
         (reduce (fn [old-str attr-entry]
                   (str old-str "  " (stringify-attr attr-entry))) "" attr-map)
         "}" (get sig-map :sterling-alloy "") " \n")))

(defn generate-assert
  "Generate the string source for an Alloy fact, given a Sterling Fact map"
  ([fact-map]
    (generate-assert fact-map "fact"))
  ([assert-map preamble-str]
    ;; check for "holds", if not there, get the "all" or "no", by dissoc "such-that"
    (let [fact-str (str preamble-str " { ")]
      (if-let [hold-str (:holds assert-map)]
        (str fact-str hold-str " }\n")
        (str fact-str
             (stringify-map (dissoc assert-map :such-that))
             (when (:such-that assert-map)
               (str " | " (:such-that assert-map)))
             " }\n")))))

(def opt-dispatch
  {:facts (fn [fact-vec] (reduce #(str %1 (generate-assert %2)) "\n" fact-vec))
   :assertions (fn [assert-map]
                 (reduce (fn [assert-str [k v]]
                           (str assert-str (generate-assert v (str "assert " (name k)))))
                         "\n" assert-map))
   :checks (fn [check-vecs]
             (reduce (fn [check-str c-vec]
                       (str check-str "check " (cstr/join " "
                                                          (map #(if (keyword? %)
                                                                  (name %)
                                                                  (str %)) c-vec)))) "\n" check-vecs))
   })

(defn generate-verification
  ""
  ([opt-name opt-data]
   (generate-verification opt-name opt-data opt-dispatch))
  ([opt-name opt-data dispatch-map]
   (let [opt-fn (get dispatch-map opt-name)]
     (opt-fn opt-data))))

(defn generate-src
  "Generate a full Alloy source file (as a string) given
  the Sterling signature maps and the verification maps"
  [sig-maps verify-maps]
  (str
    (reduce (fn [file-str [sig-name sig-map]] (str file-str (generate-sig sig-name sig-map))) "" sig-maps)
    (reduce (fn [file-str [opt-name opt-data]] (str file-str (generate-verification opt-name opt-data))) "\n" verify-maps)))

(defn temp-file [prefix suffix]
  (doto (File/createTempFile prefix suffix)
    (.deleteOnExit)))

(defn str->temp-file [s]
  (let [tf (temp-file "sterling-alloy" ".als")]
    (spit tf s)
    tf))

(defn pre-compiler []
  (let [reporter (A4Reporter.)
        options (A4Options.)
        _ (set! (. options solver) A4Options$SatSolver/SAT4J)]
    [reporter options]))

(defn compile-alloy [file-obj]
  (let [[reporter options] (pre-compiler)
        world (CompUtil/parseEverything_fromFile reporter nil (if (string? file-obj) file-obj (.getPath file-obj)))] ;; file-obj was originally filename
    (map #(vector (str %) (TranslateAlloyToKodkod/execute_command reporter (.getAllReachableSigs world) % options))
         (.getAllCommands world))))

;; TODO a reporter, maybe? for the results generated by the reporter?

(defn alloy [some-ns & kw-opts]
  (let [opts (apply hash-map kw-opts)
        alloy-sig-map (extract-alloy-signatures (ns-publics some-ns))
        alloy-src (generate-src alloy-sig-map opts)]
    (-> alloy-src str->temp-file compile-alloy)))

(comment
  (compile-alloy "src/sterling/example/filesystem/alloy/fs3.als")
  (compile-alloy (str->temp-file (slurp "src/sterling/example/filesystem/alloy/fs3.als")))
)

