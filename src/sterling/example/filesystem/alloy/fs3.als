// File system objects
abstract sig FSObject { }
// File system objects must be either directories or files.
sig File, Dir extends FSObject { }

// A File System
sig FileSystem {
  live: set FSObject,
  root: Dir & live, // The intersection of Dir and live
  parent: (live - root) ->one (Dir & live), // no root.parent; parent must be a single Dir (and part of the live FS/set)
  contents: Dir -> FSObject // no need for Dir lone-> FSObject because of parent relation
}{
  // live objects are reachable from the root
  live in root.*contents
  // parent is the inverse of contents
  parent = ~contents
}

pred example { }

run example for exactly 1 FileSystem, 4 FSObject

