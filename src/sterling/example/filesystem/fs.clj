(ns sterling.example.filesystem.fs
  (:require [clojure.walk :as cwalk]))

;; Overview
;; ==========
;;
;; A common example is to illustrate Alloy's abilities is a simpel filesystem.
;;
;; Below is a pure Clojure implementation of the same system, with the same
;; checks.
;; Sterling, Alloy, Trammel, core.contracts or any other specification is not used.

;; Protocols are open - so I can't say anything about the total set of FSObjects
;; For example, in Alloy I could say something like `{ File + Dir = FSObject }`
;; That doesn't exist here.
(defprotocol FSObject
  (repr [fs-obj]))

(defrecord FSDir [parent contents]
  FSObject
  (repr [d] d))

(defrecord FSFile [parent]
  FSObject
  (repr [f] f))

(def root  (atom (->FSDir nil [])))

(defn in-root [x]
  (let [contents (flatten (:contents root))]
    (or (identical? x root)
        (some #{x} contents))))

(defn owned [contents parent]
  (every? #(= parent (:parent %)) contents))

(defn root-replace!
  "Replace the old instance of something in the root,
  with a new instance"
  ([old new-t]
    (root-replace! old new-t root))
  ([old new-thing root-atom]
   (reset! root-atom (cwalk/postwalk-replace {old new-thing} @root-atom))))

(defn ->FSDir
  "Construct a new FSDir Record
  Arguments:
    parent - A Directory, that must also be connected to the root
    contents - A Vector of FSObjects, whose `parent` is set to this Directory"
  [parent contents]
  {:pre [(= FSDir (type parent)) ;; the parent is a single directory
         (in-root parent) ;; the parent is part of filesystem
         (vector? contents) ;; the contents are a vector
         (every? #(satisfies? FSObject %) contents) ;; all of the contents are FSObjects
         (owned contents nil)] ;; all of the contents are not owned
   :post [(some #{%} (:contents parent)) ;; the new FSDir is in the parent dir
          (in-root %) ;; sitting safely in the filesystem
          (owned contents %)]} ;; and the contents of the new FSDir are all owned by the FSDir
  (let [new-fsdir (new FSDir parent contents)
        new-fsdir (assoc new-fsdir :contents (map #(assoc % :parent new-fsdir) contents))
        new-parent (update-in parent [:contents] conj new-fsdir)
        new-root (root-replace! parent new-parent root)]
    new-fsdir))

