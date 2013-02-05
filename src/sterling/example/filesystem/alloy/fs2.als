
/*
This is a simplistic (and naive) example of a potential File System.
The idea was pulled from a tutorial:
http://alloy.mit.edu/alloy/tutorials/online/frame-FS-1.html
*/
module fs2
open util/relation as rel

// A file system object in the file system
abstract sig FSObject { parent: lone Dir }

// File system objects must be either directories or files.
// A directory in the file system
sig Dir extends FSObject { contents: set FSObject }

// A file in the file system
sig File extends FSObject { }

// There exists a root
one sig Root extends Dir { }

// File system is connected
fact { all x:FSObject-Root | one x.parent }

// A directory is the parent of its contents
// ie: parent is the inverse of contents
fact { contents = ~ parent }

// The contents path is acyclic
fact { acyclic[contents, Dir] }

