Sterling and core.specs
=======================

Clojure's rich interactive development encourages developers to explore a solution space while experimenting within a problem domain. 
But what if those explorations could be captured as tangible specifications, and used to automatically generate tests and documentation, 
be applied as contracts for functions, used in external verification systems, and remained open for extension?

The following code explores the advantages of unifying core.contracts, test.generative, and external systems under a single common specification, 
captured as a value.


### Rationale

Specification-as-a-value serves as a useful tool that guides developers through all phases of the software development lifecycle: from design to deployment. 
A single specification could ensure your conceptual design is complete, that your functions conform to the design at runtime, 
and the functions pass an array of automatically generated, random tests.

I was inspired by Bertrand Meyer's [A fundamental duality of software engineering](http://cacm.acm.org/blogs/blog-cacm/156428-a-fundamental-duality-of-software-engineering/fulltext)
and previous work found in Eiffel's AutoTest

I also drew a lot from reading [Eiffel as a framework for verification](http://se.inf.ethz.ch/old/people/meyer/publications/lncs/eiffel-vstte.pdf) and  [Quickcheck: a lightweight tool for random testing of Haskell programs](http://www.cs.tufts.edu/~nr/cs257/archive/john-hughes/quick.pdf).
Other works include [An overview of Ciao](http://clip.dia.fi.upm.es/papers/RuleML11_slides.pdf) ( *thanks David Nolen* ), many of the papers from [Practical aspects of declarative languages - 2007](), and [Software Abstractions](http://books.google.com/books?id=DDv8Ie_jBUQC).

### Notice

_The code contained here is for exploration only_ - do not use ANY of this in production.

That said, have fun poking around!  Ping me with ideas and feel free to contribute anyway you like.  Feedback and conversations are very welcome.

The idea
---------

test.generative's spec can serve multiple purposes:

 * It can be a formal spec for the function
   * That spec can then be used in a system like [Alloy](http://alloy.mit.edu/alloy/index.html), provided the conversion works [System analysis and model checking for free]
 * It can be a contract for a given function.
   * Provided a function might have multiple specs (assumption), they can be comp'd to form the final contracts

Similarly, core.contracts can:

 * Be seen as the spec for which to generate the generative tests from (this was done in [Eiffel](http://www.eiffel.com/general/column/2004/september.html))
 * It can serve as the spec for Alloy
   (in similar way that [JForge](http://sdg.csail.mit.edu/forge/plugin.html)/[JML](http://www.eecs.ucf.edu/~leavens/JML//index.shtml)/[DynAlloy](http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.69.6112&rep=rep1&type=pdf)
   are used with Java).
 * Can be enhanced with more relational predicates

The idea is to create a general, open specification library in Clojure.
The specification itself is just Clojure data (most likely a map) - a value.

The spec could serve as input to various other backends/efforts like test.generative, core.contracts, and an Alloy API Interop, or be queried directly using datalog/core.logic/etc
The spec would be as easy writing a contract/invariant.

### Why do this?

A single specification on the code will:
 * Ensure guarantees on the running system via contracts
 * Provide free generative testing
 * Allow you check your system's specification for completeness
 * Enable you to enhance your code base with more documentation, additional checks, and provide a platform for in-depth querying


### Additional work

One interesting feature in Eiffel is the ability to toggle certain contracts off in production mode.
This becomes more important in detailed-specs-as-contracts, for which you may only want to verify a model

For example:

 * Is my [query language/XPath/datalog] design and implementation complete?
 * Is my [interaction/network protocol/data protocol] design and implementation complete?
 * Is there an open vulnerability or flaw in my security mechanism
 * Show me which cases are underspecified or otherwise fail

## Usage

### core.specs
The core specification-as-a-value can be found in the `clojure.core.specs.clj` file.

The main points of entry are: `raw-spec`, `defspec`, `fn-with`, and `example-str`

You can see how all of these are used in `src/sterling/example.clj`

### Alloy // sterling
I haven't finished roping Alloy into core.specs fully.  You can see example usage in `src/sterling/examples/filesystem/` and `src/sterling/alloy.clj`

### test.generative
This code uses a modified test.generative, which supports core.specs as valid generative tests

### core.contracts
I'm in the middle of some gruesome updates and adjustments to core.contracts.

Currently, core.specs just generates new functions (ala `fn-with`) with the `:pre` and `:post` conditions patched up.

## License

Copyright © 2012 Paul deGrandis

Distributed under the Eclipse Public License, the same as Clojure.

