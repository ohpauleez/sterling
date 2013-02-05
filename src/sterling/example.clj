(ns sterling.example
  (:require [clojure.core.specs :as spec]
            [clojure.test.generative.runner :as runner]
            [typed.core :refer [cf]]))

(spec/defspec tight-inc
    inc
    "An inc that only works for inputs 0-49"
    [^{:uniform [0 50] :enforced true} x]
    :constraints [["The output will always be less than or equal to 50"
                   => (<= % 50)]]
    :typed [[Number -> Number]])

;; This will run all generative tests for the current namespace.
;; Specs can be used as tests
(defn tests [] (runner/run-generative-tests))


(comment

  ;; A preview of some Specifications.
  ;; Out of the box, a single spec can be used with:
  ;;   test.generative, core.contracts, Typed Clojure, and Sterling (an interface to Alloy)
  ;; You're also free to extend the system however you need.
  
  ;; Here is an example of a simple specification.
  ;; Under the hood, specs are just maps.  `raw-spec` just returns the map
  (def inc-spec
    (spec/raw-spec
      inc
      "A simple spec for non-negative inc" ; Optional docstring
      '[^long x]
      :constraints '[["The input is non-negative and always returns a positive number"
                      (not (neg? x)) => (pos? %)]]))

  ;; The map looks like this:
  ;{:clojure.core.specs/type :defspec,
  ; :clojure.core.specs/f #<core$inc clojure.core$inc@6d6a8bf0>,
  ; :clojure.core.specs/args [x],
  ; :clojure.core.specs/ext {:constraints [{:doc "The input is non-negative and always returns a positive number", :pre (not (neg? x)
  ;                                         :pre (not (neg? x)), :post (pos? %)}]
  ;                          :typed  [[Number -> Any]]},
  ; :clojure.core.specs/doc "A simple spec for non-negative inc"}

  ; You'll notice type information was added...
  ; Specifying type information is optional.  It'll be used if supplied,
  ;   otherwise core.specs will attempt match types based on :tag information

  ;; These next two are the same.
  ;; Testing distributions can be "enforced" and used a contracts/constraints
  (spec/raw-spec
    inc
    "An inc that only works for inputs 0-49"
    '[^{:uniform [0 50] :enforced true} x]
    :constraints '[["The output will always be less than or equal to 50"
                    => (<= % 50)]]
    :typed '[[Number -> Number]])

  (spec/raw-spec
    inc
    "An inc that only works for inputs 0-49"
    '[^{:uniform [0 50] :enforced true} x]
    :constraints '[["The output will always be less than or equal to 50"
                    :post (<= % 50)]]
    :typed '[[Number -> Number]])

  (spec/raw-spec
    inc
    "An inc that only works for inputs 0-49"
    '[^{:tag (uniform 0 50)} x]
    :constraints '[["The input must be between 0-49"
                    ;(and (>= x 0) (<= x 49))
                    (spec/between? 0 <= x <= 49)]
                   ["The output will always be less than or equal to 50"
                    => (<= % 50)]]
    :typed '[[Number -> Number]])

  (spec/defspec tight-inc
    inc
    "An inc that only works for inputs 0-49"
    [^{:uniform [0 50] :enforced true} x]
    :constraints [["The output will always be less than or equal to 50"
                   => (<= % 50)]]
    :typed [[Number -> Number]])

  ;; The specs can be used like decorators, generating the constrained
  ;; forms of the function detailed in the spec.
  ;; The following generates a new function with the constraints and type
  ;; information added.
  ;;
  ;;    (def constrained-fn (spec/fn-with a-raw-spec :constraints :typed))

  ;; Here is an example from our earlier spec...
  (def pos-inc-fn (spec/fn-with tight-inc :constraints))
  (pos-inc-fn 5)
  (def typed-inc (spec/fn-with tight-inc :typed))
  (typed-inc 5)

  ;; We can also see idiomatic use of the spec'd function:
  ;;   The following returns a random example: "(tight-inc 37  =>  38")"
  (spec/example-str #'tight-inc)

  ;; Or you can look at the raw map, which generates the example via test.generative
  (spec/example #'tight-inc)


  ;; TODO:
  ;; This fails, because it's looking at the var for info
  (cf (pos-inc-fn 30))
  ;; This goes down the rabbit hole of typing hell
  (cf ((spec/fn-with tight-inc :constraints :typed) 20))

  ;;TODO - auto add type information with a dispatch table based on tag values
  ;;TODO - hook in the core.contracts :constraints backend - currently just patching to :pre and :post
  ;;TODO - hook in Typed Clojure
)

