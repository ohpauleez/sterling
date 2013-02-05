/* 

     Alloy version of XPath 1.0 data model

          C. M. Sperberg-McQueen
          19-26 January 2010

          Rev. 28 January 2010 (see change log at end)

*/
/* Copyright (c) 2010 Black Mesa Technologies LLC */
/* Extended and modified by Paul deGrandis */

module xpath10

/****************************************************************
1 Introduction 
****************************************************************/

/* This Alloy model consists of a more or less direct translation into
Alloy of the specification of the XPath 1.0 data model in the XPath
1.0 specification [W3C 1999].  Note that the focus is on the data
model; no attempt is made here to describe the full semantics of XPath
1.0.

The model presented is intended to serve several purposes:

  - as a simple exercise in Alloy

  - as a standard library resource for use by other Alloy models
    describing specifications or software building on this model

  - as a tool for checking the definition of the XPath 1.0 model for
    completeness and correctness

  - as a tool for checking possible reformulations of the model for
    completeness and correctness

The presentation assumes that the reader has at least a passing
familiarity with XML [W3C 2008] and XPath 1.0 [W3C 1999], or else a
capacity for following discussions of unfamiliar material without
discomfort.  A beginner's familiarity with the Alloy notation [Jackson
2006] will also be helpful, but every important formula given in Alloy
is also paraphrased in English, so that readers unfamiliar with the
notation should be able to follow the main lines of the development
even if they miss some details.

To make it easier to check the correspondence of the Alloy formulation
to the prose of the specification, we interleave the two: first a
quotation from the spec, then the Alloy formulation, together with any
commentary that seems helpful.  The extracts from the specification
are given in document order, for the benefit of readers who wish to
follow along in context.  Spec passages not relevant for modeling 
purposes are omitted.

Experience suggests that a few words about the assumptions of the work
and the nature of the commentary may be in order so as to reduce the
likelihood of misunderstandings by some readers.

The author's assumption is that one purpose of including an explicit
definition of a "data model" in the XPath 1.0 specification is to lay
out explicitly the formal relations among the objects in an XML
document, as that document is operated upon by an XPath 1.0 processor.
These relations have long been familiar to users of SGML and XML and
they are closely tied to properties built into XML by the rules of the
grammar given in [W3C 2008].  One purpose of formulating them
explicitly, in terms mostly independent of the XML grammar, is to
establish that any data structure representing the abstract data model
described here can be operated upon by software using this data model,
whether the data structure was created by parsing an XML document or
by other means.  In such an exercise it is preferable not to leave any
important assumptions vague or implicit, and not to appeal to common
knowledge, common belief, or the XML spec itself.  It is also a
natural goal to make the definition of the data model complete and
self-explanatory, free of reliance on rules given elsewhere in the
specification.

In some cases, constructs and rules given elsewhere in the XPath 1.0
spec rely upon certain properties being true of any instance of the
data model; these constructs and rules may be ill-defined or
non-sensical if those properties are not in fact guaranteed.  For
example, the rest of the XPath 1.0 specification assumes that any node
in a data model instance has at most one parent, also that it has at
most one immediate left neighbor and at most one immediate right
neighbor.

In these cases, I believe the authors of the XPath 1.0 spec intended
the properties in question to be guaranteed by the definition of the
model and believed that they were in fact guaranteed; I do not believe
that they intended the implicit assumption of those properties
elsewhere in the spec to constitute an additional constraint upon
instances of the data model.  Now in point of fact, the definition of
the data model in section 5 of [W3C 1999] does not in fact guarantee
all the properties assumed elsewhere.  Uniqueness of the parent is
guaranteed, for example, while uniqueness of immediate neighborhood is
not, at least if the formalization presented here is correct.  In
these cases I believe the failure of the model to guarantee the
property assumed by the rest of the XPath 1.0 spec reflects an
unintended flaw in the definition of the data model.  I do not believe
that it reflects a decision to specify the required properties
obliquely, by formulating other rules which silently assume that
properties hold.  The assumptions made in the rest of the
specification make clear, in these cases, what was intended.  But they
do not constitute part of the definition of the data model and do not
fill the gaps in the definition.

In cases where the model is underspecified, the entailments of the
rest of the XPath spec have naturally enough made clear to
implementors what is expected, so in fact implementations of XPath 1.0
typically exhibit consistent behavior.  This fact will suggest to some
readers that there really is no problem, because there is no
uncertainty in practice about what was intended.  If I insist upon
saying that the data model does not determine a unique answer to
certain questions, it is not because I am unfamiliar with the original
working groups' intent and with current implementation practice.  If I
regard the gaps in the definition as flaws to be corrected, it is not
because I believe that the gaps have led to interoperability problems
but because I believe that the creators of the spec intended the
definition of the data model to be complete and self-sufficient.  They
came close enough to that goal that it would be a shame not to go the
rest of the way if we can.  A tool like Alloy can help in the careful
analysis necessary.

*/

/****************************************************************
2 General
****************************************************************/


/* We begin at the beginning of section 5 of [W3C 1999], entitled
"Data Model."

    XPath operates on an XML document as a tree. This section
    describes how XPath models an XML document as a tree. This model
    is conceptual only and does not mandate any particular
    implementation. The relationship of this model to the XML
    Information Set [XML Infoset] is described in [B XML Information
    Set Mapping].

    XML documents operated on by XPath must conform to the XML
    Namespaces Recommendation [XML Names].

This Alloy formulation does not go into the details of the Namespaces
specification (but see the definition of the Name signature and the
name_eq predicate in section 3 below). */

/****************************************************************
2.1 Nodes
****************************************************************/

/*

    The tree contains nodes. There are seven types of node:

        - root nodes
        - element nodes
        - text nodes
        - attribute nodes
        - namespace nodes
        - processing instruction nodes
        - comment nodes

    For every type of node, there is a way of determining a
    string-value for a node of that type. For some types of node, the
    string-value is part of the node; for other types of node, the
    string-value is computed from the string-value of descendant
    nodes.

We define an abstract signature Node, which will have Root, Element,
etc. as refinements.  We'll give Node a stringvalue property, though
at the moment this formalization does nothing useful with it.  Node
also has a parent property, though the spec has not yet mentioned it
(see below).

*/

abstract sig Node {
  stringvalue : UCSstring,
  parent : lone Node
}

// The Alloy Analyzer seems to treat 'String' as a reserved name, so
// we'll call it UCSstring.

sig UCSstring {}

/****************************************************************
2.2 Expanded names
****************************************************************/

/* The Namespaces recommendation [W3C 2009] defines 'qualified names'
(QNames) consisting of a namespace prefix (bound by the context to a
namespace URI) and a 'local name', separated by a colon.  For example
'mathml:equation'.  The interpreted form of a QName is an expanded
name:

    Some types of node also have an expanded-name, which is a pair
    consisting of a local part and a namespace URI. The local part is
    a string. The namespace URI is either null or a string. The
    namespace URI specified in the XML document can be a URI reference
    as defined in [RFC2396]; this means it can have a fragment
    identifier and can be relative. A relative URI should be resolved
    into an absolute URI during namespace processing: the namespace
    URIs of expanded-names of nodes in the data model should be
    absolute. Two expanded-names are equal if they have the same local
    part, and either both have a null namespace URI or both have
    non-null namespace URIs that are equal.

We define Name in the obvious way, as an expanded name.  We have no
other form of names, so there is no need to call this one an
'expanded' name; there is no other kind of name here.
*/

sig Name {
  NSName : lone UCSstring,
  Localname : UCSstring
}

pred name_eq[a, b : Name] {
  a.NSName = b.NSName
  and
  a.Localname = b.Localname
}


/****************************************************************
2.3 Document order
****************************************************************/

/* The spec then defines the term 'document order', which plays a
central role in the semantics of XPath 1.0.

    There is an ordering, document order, defined on all the nodes in
    the document corresponding to the order in which the first
    character of the XML representation of each node occurs in the XML
    representation of the document after expansion of general
    entities. Thus, the root node will be the first node. Element
    nodes occur before their children. Thus, document order orders
    element nodes in order of the occurrence of their start-tag in the
    XML (after expansion of entities). The attribute nodes and
    namespace nodes of an element occur before the children of the
    element. The namespace nodes are defined to occur before the
    attribute nodes.  The relative order of namespace nodes is
    implementation-dependent. The relative order of attribute nodes is
    implementation-dependent. Reverse document order is the reverse of
    document order.

Several aspects of this definition invite comment in the context of
formalization:

  - The description given seems to imply that the full details of
    the ordering follow from the cases given.  It will be interesting
    to see if they do.

  - Note that by itself, the rule that parent nodes precede their
    children does NOT guarantee, as the spec suggests, that element
    nodes occur in the order of the occurrence of their start-tags in
    the XML document.

    The text implicitly assumes a rule that Document order for
    siblings follows the order assigned by their parent's ordered list
    of children (supplied in the definition of basic precedence
    below).  In the rather pedantic state of mind encouraged by
    exercises like this one, this seems something one might have
    expected to be stated explicitly.  But the XPath 1.0 spec
    was not written by pedants.

  - It's not completely clear in what vein to take the references to
    the order of character representations in XML syntax.

    On the face of it, at least some of the references appear to be
    informative, not normative, intended to provide context and help
    confirm the reader's understanding of the normative statements.
    The order being defined is intended to correspond to the order of
    character representations in the XML syntax, and some of the
    individual constraints have obvious analogues in the grammar of
    XML.  If the references to XML syntax were intended as part of the
    actual specification of the ordering, there would be no need for
    several of the statements in the paragraph about the relative
    positions of parents, attributes, and children.

    The rules concerning namespace nodes and attributes, on the other
    hand, do not in the general case agree with the ordering of
    character representations in the XML.

    Some readers, however, may disagree and take the mentions of
    serial-form XML as substantive and normative (except as overridden
    by the other rules given).  Such readers will correspondingly find
    some aspects of the formalization here to disagree with.  Note,
    however, that a NORMATIVE appeal to the order of character
    representations in XML syntax would, to be effective, require an
    explicit account of the mapping between XML surface syntax and
    data model instance which is not in fact given in the spec.
    
  - The spec mentions an "ordering".  It seems likely that a total
    order is intended, but this is not explicitly specified, and in
    most contexts a partial ordering is in fact counted as an
    ordering.

To derive a general ordering covering all nodes from the basic cases
explicitly specified, we define two predicates, 'basic_precedes' for
the primitive cases, and 'precedes' for the transitive closure.

(Alloy note: it might be more convenient to define some
immediate-precedes relation on Node, so that the general 'precedes'
could just be "b in a.^immediate_precedes", but the current
formulation seems closer to the spec so we stick with it.  The
alternative formulation may be worth experimenting with, sometime.)

*/

pred basic_precedes[disj a, b : Node] {

  // the root node is first, so it precedes everything
  (a in Root)

  // parents precede their children
  or (a + b in Element and a = b.parent)
  or (a in Element and b in (Attribute + NSNode) and a = b.parent)
  or (a in NSNode and b in Attribute and a.parent = b.parent)

  // "The attribute nodes and namespace nodes of an element 
  // occur before the children of the element." 
  or (a in (Attribute + NSNode) and b in Element and
    a.parent = b.parent)

  // "The namespace nodes are defined to occur before the 
  // attribute nodes."
  or (a in NSNode and b in Attribute and a.parent = b.parent)

  // The next clause is implicit in the text; I think it is clear
  // from the statement about start-tags and from the description 
  // of ordered child nodes that this is intended.
  or (a + b in Element and a.parent = b.parent
      and a.parent.chseq.idxOf[a] < a.parent.chseq.idxOf[b])
}

// a precedes b, in general, if there is a chain of basic_precedes
// relations
pred full_precedes[a, b : Node] {
  basic_precedes[a,b]
  or 
  some c : Node | basic_precedes[a,c] and full_precedes[c,b]
}

/* Note: Oops.  The definition just given, being recursive, is not
suitable for Alloy.  Found this out much later; I should have run the
Analyzer more frequently along the way.  We'll need to provide a
different definition of document order using some sort of 'precedes'
relation on nodes, and transitive closure. */

/****************************************************************
2.4 Children, parents, descendants
****************************************************************/

/* 

    Root nodes and element nodes have an ordered list of child
    nodes. Nodes never share children: if one node is not the same
    node as another node, then none of the children of the one node
    will be the same node as any of the children of another node.

We model the ordered list of child nodes with a chseq property whose
value is a sequence of nodes.  It is convenient to be able to refer to
the children as a set, so we define the property ch, whose value is a
set of nodes, as the set of elements in the sequence chseq.  (The
first pair of braces in an Alloy signature declaration enclose
declarations of properties of instances of that signature; the second
pair encloses constraints holding for all instances of the signature.)

*/

abstract sig NodeWithChildren extends Node {
  chseq : seq Node,
  ch : set Node
}{
  ch = chseq.elems
}

/* The prohibition on shared children is most conveniently formulated
as a fact, i.e. a constraint holding for all instantiations of the
model. But in fact there is no need to state it as a fact:  it follows
from the other rules given, in particular the statement immediately
following that every node other than the root has exactly one
parent. */

assert no_shared_children {
  all disj p, q : NodeWithChildren |
    // the intersection of P's children with Q's children is the empty set
    no (p.ch & q.ch)
}
check no_shared_children for 7


/* "Every node other than the root node has exactly one parent, 
which is either an element node or the root node. A root node 
or an element node is the parent of each of its child nodes."
*/
// None of these follow from other constraints as currently 
// formulated; all must be stated explicitly.  
fact only_root_parentless {
  all n : Node | #(n.parent) = 0 iff (n in Root) 
}
fact parent_type {
  univ.parent in (Element + Root)
}
fact parent_child {
  ~ch in parent
}


/* "The descendants of a node are the children of the node 
and the descendants of the children of the node."
*/
fun descendants[ n : Node ] : set Node {
  n.^ch
}

/****************************************************************
2.5 A note on node identity and element identity
****************************************************************/

/* The XML spec is programmatically vague about ontological questions;
XML may be processed using many different models.  It provides a
grammar and additional constraints which together make it possible to
distinguish XML data streams from other data streams, but the XML spec
does not attempt to say what kind of thing an XML document is, or when
in the general case XML constructs are to be treated as identical,
distinct but equivalent, or different.  In the following document, for
example, it may be convenient in one application to treat the two
occurrences of the string "<b/>" as denoting two occurrences of "the
same element", and in another application to treat the two occurrences
as two distinct elements.

  <a><b/><c><b/></c></a>                                     (1)

The idea that there is only one 'b' element in this document is not
chosen at random; since XML defines a grammar for all XML documents,
it is not unnatural to hold, as some have done, that an XML document
is essentially a sequence of characters (and similarly for XML
elements).  In normal usage, the term 'sequence of characters' is
taken as meaning a sequence of character-types, not of
character-tokens.  We might say that there are two occurrences of *the
element* "<b/>" in document (1), rather than two elements with the
same character representation, just as we say that the integer three
occurs twice in the fourth line of Pascal's triangle (1, 3, 3, 1) and
not that there are two distinct integers named three which are here
written using the same numeral (or similar numerals?).

It might in retrospect have been useful to prescribe a usage for these
questions, but for better or worse the creators of XML did not do so.

In defining a model to be used for particular software operating on
XML documents, however, it is clearly helpful to make clear which
notion of element identity is to be used.  The XPath 1.0 data model,
for example, specifies by means of the rule against shared children
(see section 2.4 above) that in document (1) there are two 'b'
elements, not one.

Oddly, the spec does NOT say explicitly that no two positions in the
list of children are occupied by the same element.  Would it be
consistent with the definition of the data model to hold that in the
document

    <a><b/><b/><b/></a>                                      (2)

there is only one b element?  It is clearly not the intended
interpretation, since the definition of the preceding-sibling and
following-sibling axes elsewhere in the XPath 1.0 specification
assumes that each element node has a unique preceding and a unique
following sibling (except the first and last children of a given
parent, which lack predecessor and successor respectively).  But while
the spec includes an explicit rule about parentage, it includes no
explicit rule requiring the sequence of children to be an injection
(i.e. requiring all siblings to be distinct nodes).  If there is any
way to prove, from the specification of the data model, that there are
four distinct element nodes in the model instance for document (2),
and not two, I have not seen it.

Alloy's analysis makes clear that the disjointness of siblings does
not follow from the other rules specified; the instances generated by
the Alloy Analyzer include numerous cases of the same node appearing
more than once among the children of its parent.  An explicit test of
documents (1) and (2) shows the difference.

*/

lone sig A, B, C extends Name {}
pred document_1[r : Root, a, b, c : Element] {
    
  // Three elements named in the obvious say
  a.gi = A
  b.gi = B
  c.gi = C

  // None of them has any attributes
  no (a.atts + b.atts + c.atts)

  // A is the document element, the single child of root.
  r.chseq = {0 -> a}

  // The elements have the parent-child relations shown:
  a.chseq = {0 -> b} + {1 -> c}
  b.chseq.isEmpty
  c.chseq = {0 -> b}
}

// Owing to its violation of the no-shared-children rule,
// predicate document_1 has no instances, as can be
// seen by running the document_1 predicate in any 
// suitable scope.
run document_1 for 3 // but 1 Root, 1 A, 1 B, 1 C
run document_1 for 7

pred document_2 [r : Root, a : Element] {
  // rather than specify a particular configuration, we'll
  // describe the constraints and let Alloy decide how many
  // nodes to use for the children of A.

  // element A has gi A, no attributes, and three children.
  a.gi = A
  and no (a.atts)
  and #(a.chseq) = 3

  // A is the document element, the single child of root.
  and r.chseq = {0 -> a}

  // Each child of A has the same GI, no children, no atts
  and (all c : Node | 
    (c in a.ch) 
    implies
    (c in Element and c.gi = B and #(c.atts) = 0 and #(c.ch) = 0))

}
// When we ask for instances of document_2, we can see that
// Alloy finds instances with four distinct elements, but also with 
// two.  And three.
run document_2 for 3 but 1 Root, 4 Element

// If the number of instances generated becomes burdensome,
// it may be convenient to select just those in which A has a 
// particular number of distinct children 

pred document_2_select {
  some a : Element | some r : Root |
  document_2[r, a]
  and #(a.ch) = 3 // 1, or 2, or 3 (larger numbers have no instances)
}
run document_2_select for 7

/*

As a side note: The XML Information Set specification [W3C 2004]
similarly has no rule specifying whether an information item can
appear more than once in the ordered list of its parent's children; in
the Infoset, the prohibition against parents sharing children follows
naturally from the fact that each element information item is
specified as having a [parent] property.

If we wish to assume, for purposes of exploration, that all the
elements in a parent's sequence of children are pairwise distinct, we
can do so by specifying the predicate chseq_injective.  It specifies
that for any node n, when the relation n.chseq (which maps from
integers to nodes) and its transpose ~(n.chseq) are composed, each
integer in the domain is mapped back to itself, and not to any other
integer.  That is, the chseq relation is injective.

A second formulation may be clearer to some.  The predicate
chseq_nodups uses the standard function hasDups to test whether the
sequence n.chseq contains duplicate items.  

The assertion 'nodup_injective' asserts that these two predicates are
true in exactly the same cases.

*/

pred chseq_injective {
  all n : Node | n.chseq.~(n.chseq) in iden
}
pred chseq_nodups {
  all n : Node | not n.chseq.hasDups
}
assert nodup_injective {
  chseq_nodups iff chseq_injective
}
check nodup_injective for 7


/****************************************************************
3 Individual node types
*****************************************************************
3.1 The root node
****************************************************************/

/* Section 5.1 of the spec describes root nodes.

    The root node is the root of the tree. A root node does not occur
    except as the root of the tree. The element node for the document
    element is a child of the root node. The root node also has as
    children processing instruction and comment nodes for processing
    instructions and comments that occur in the prolog and after the
    end of the document element.

    The string-value of the root node is the concatenation of the
    string-values of all text node descendants of the root node in
    document order.

    The root node does not have an expanded-name.

We formalize this with a Root signature, whose children are
constrained to include only processing instructions, comments, and
exactly one element.  We ignore the rule about string-value for now.

*/

sig Root extends NodeWithChildren {}{
  ch in (PI + Comment + Element)
  #(ch & Element) = 1
}

/****************************************************************
3.2 Element nodes
****************************************************************/

/*  Section 5.2 describes element nodes.

    There is an element node for every element in the document. An
    element node has an expanded-name computed by expanding the QName
    of the element specified in the tag in accordance with the XML
    Namespaces Recommendation [XML Names]. The namespace URI of the
    element's expanded-name will be null if the QName has no prefix
    and there is no applicable default namespace.

        NOTE: In the notation of Appendix A.3 of [XML Names], the
        local part of the expanded-name corresponds to the type
        attribute of the ExpEType element; the namespace URI of the
        expanded-name corresponds to the ns attribute of the ExpEType
        element, and is null if the ns attribute of the ExpEType
        element is omitted.

    The children of an element node are the element nodes, comment
    nodes, processing instruction nodes and text nodes for its
    content. Entity references to both internal and external entities
    are expanded. Character references are resolved.

    The string-value of an element node is the concatenation of the
    string-values of all text node descendants of the element node in
    document order.

Again, we ignore string value rules for now.  We also ignore the
treatment of unique ID values for elements.

Section 5.3 also mentions something relevant to elements:

    Each element node has an associated set of attribute nodes; the
    element is the parent of each of these attribute nodes; however,
    an attribute node is not a child of its parent element.

*/

sig Element extends NodeWithChildren {
  gi : Name,
  atts : set Attribute,
  nss : set NSNode
}{
  ch in (Element + Comment + PI + Textnode)
  all a : atts | this = a.@parent
  all n : nss | this = n.@parent
}

/****************************************************************
3.3 Attribute nodes
****************************************************************/

/* Section 5.3 describes attribute nodes:

    Each element node has an associated set of attribute nodes; the
    element is the parent of each of these attribute nodes; however,
    an attribute node is not a child of its parent element.

        NOTE: This is different from the DOM, which does not treat the
        element bearing an attribute as the parent of the attribute
        (see [DOM]).

The constraint on ch, in the definition of the Element signature,
guarantees that no attribute node is a child of its parent.

    Elements never share attribute nodes: if one element node is not
    the same node as another element node, then none of the attribute
    nodes of the one element node will be the same node as the
    attribute nodes of another element node.

        NOTE: The = operator tests whether two nodes have the same
        value, not whether they are the same node. Thus attributes of
        two different elements may compare as equal using =, even
        though they are not the same node.

This already follows from other rules (specifically the definition of
the parent relation, which says each node has at most one parent, and
the second constraint on the Element signature.  We can check that it
does in fact follow by means of a simple Alloy assertion.  Alloy finds
no counter-examples.*/

assert att_parent_is_function {
  all disj e, f : Element | no (e.atts & f.atts)
}
check att_parent_is_function for 5

/* Attributes have names:

    An attribute node has an expanded-name and a string-value. The
    expanded-name is computed by expanding the QName specified in the
    tag in the XML document in accordance with the XML Namespaces
    Recommendation [XML Names]. The namespace URI of the attribute's
    name will be null if the QName of the attribute does not have a
    prefix.

And attribute nodes are disjoint from namespace nodes (though both are
represented by attributes, within the meaning of the XML
specification).

    There are no attribute nodes corresponding to attributes that
    declare namespaces (see [XML Names]).

We define a name property for the name; the string-value property is
inherited from Node.  The Attribute and NSNode signatures are declared
as extensions of Node, which guarantees that they are disjoint.  So
nothing more is needed for attributes than the following
declaration. */

sig Attribute extends Node {
  name : Name,
  value : UCSstring
}

/* There's a gap in the model here:  nothing in the definition
of the model says that no two attributes on the same element
have the same name. */


/****************************************************************
3.4 Namespace nodes
****************************************************************/

/* Section 5.4 describes namespace nodes:

    Each element has an associated set of namespace nodes, one for
    each distinct namespace prefix that is in scope for the element
    (including the xml prefix, which is implicitly declared by the XML
    Namespaces Recommendation [XML Names]) and one for the default
    namespace if one is in scope for the element. The element is the
    parent of each of these namespace nodes; however, a namespace node
    is not a child of its parent element. Elements never share
    namespace nodes: if one element node is not the same node as
    another element node, then none of the namespace nodes of the one
    element node will be the same node as the namespace nodes of
    another element node. This means that an element will have a
    namespace node:

    - for every attribute on the element whose name starts with
      xmlns:;

    - for every attribute on an ancestor element whose name starts
      xmlns: unless the element itself or a nearer ancestor redeclares
      the prefix;

    - for an xmlns attribute, if the element or some ancestor has an
      xmlns attribute, and the value of the xmlns attribute for the
      nearest such element is non-empty

          NOTE: An attribute xmlns="" "undeclares" the default
          namespace (see [XML Names]).

    A namespace node has an expanded-name: the local part is the
    namespace prefix (this is empty if the namespace node is for the
    default namespace); the namespace URI is always null.

    The string-value of a namespace node is the namespace URI that is
    being bound to the namespace prefix; if it is relative, it must be
    resolved just like a namespace URI in an expanded-name.

For the immediate purposes of this model there is no need to model
namespace nodes and their inheritance; it may be a helpful extension
for the future, but for now we'll just treat namespace nodes as an
unexamined primitive concept.  */

sig NSNode extends Node {}

/****************************************************************
3.5 Processing instruction nodes
****************************************************************/

/* Section 5.5 of the spec describes processing-instruction nodes:

    There is a processing instruction node for every processing
    instruction, except for any processing instruction that occurs
    within the document type declaration.

    A processing instruction has an expanded-name: the local part is
    the processing instruction's target; the namespace URI is
    null. The string-value of a processing instruction node is the
    part of the processing instruction following the target and any
    whitespace. It does not include the terminating ?>.

        NOTE: The XML declaration is not a processing
        instruction. Therefore, there is no processing instruction
        node corresponding to the XML declaration.

There seems no particular point in modeling the details here; they are
not the source of any particular obscurity or the focus of any
noticeable design concern.  But it's easy enough and (unlike modeling
the details of NSNode inheritance) does not require extensive
reworking of the existing model.  So let's do it.  A PI has an
expanded_name and a target; the expanded name has no NSName part, and
the local name is the same as the target. */

sig PI extends Node {
  expanded_name : Name,
  target : UCSstring
}{
  no expanded_name.NSName
  expanded_name.Localname = target
}

/****************************************************************
3.6 Comment nodes
****************************************************************/

/* Section 5.6 describes comment nodes:

    There is a comment node for every comment, except for any comment
    that occurs within the document type declaration.

    The string-value of comment is the content of the comment not
    including the opening <!-- or the closing -->.

    A comment node does not have an expanded-name.

*/
sig Comment extends Node {}

/****************************************************************
3.7 Text nodes
****************************************************************/

/* And finally section 5.7 of the spec describes text nodes:

    Character data is grouped into text nodes. As much character data
    as possible is grouped into each text node: a text node never has
    an immediately following or preceding sibling that is a text
    node. The string-value of a text node is the character data. A
    text node always has at least one character of data.

    Each character within a CDATA section is treated as character
    data. Thus, <![CDATA[<]]> in the source document will treated the
    same as &lt;. Both will result in a single < character in a text
    node in the tree. Thus, a CDATA section is treated as if the
    <![CDATA[ and ]]> were removed and every occurrence of < and &
    were replaced by &lt; and &amp; respectively.

        NOTE: When a text node that contains a < character is written
        out as XML, the < character must be escaped by, for example,
        using &lt;, or including it in a CDATA section.

    Characters inside comments, processing instructions and attribute
    values do not produce text nodes. Line-endings in external
    entities are normalized to #xA as specified in the XML
    Recommendation [XML].

*/

sig Textnode extends Node {}

/****************************************************************
4 Conclusion
****************************************************************/

/* Since one of the purposes of this model is to illustrate how Alloy
can be used to check a specification like section 5, it will perhaps
be helpful to define some predicates that can be used to make Alloy
generate instances of the model with various properties.  The
following predicates and run commands are intended for that
purpose. */

// One document
pred single_doc {
  #Root = 1
}
// One document with no duplicates among siblings
pred single_doc_nodups {
  single_doc
  chseq_nodups
}
// One document with duplicates among siblings
pred single_doc_yesdups {
  single_doc
  not chseq_nodups
}
run single_doc for 5
run single_doc_nodups for 5
run single_doc_yesdups for 5

/* If one examines enough instances of these predicates, one will
discover a flaw in the formalization of the parent relation here: we
have ensured that each node has at most one parent, and we have
ensured that when node A has node B as child or attribute, then B has
A as parent.  But we have not ensured that when node B has node A as a
parent, then A has B as a child or attribute or NSNode.  This
predicate will generate examples of this gap. */

pred unacknowledged_children {
  parent != ~(ch + atts + nss)
}
run unacknowledged_children for 5

/* Note also that as currently defined, the parent relation is not
guaranteed acyclic; examples of elements which are their own parent
(but not their own child) crop up in the instances of unacknowledged
children.

It's probably fair to say that this problem is a failure in the
formulation of this model and not necessarily a flaw in the prose
definition of the model; it seems plausible to assume that a relation
labeled with names like parent and child is intended to be irreflexive
and acyclic unless otherwise stated (just as algebraists used to
assume that any operation denoted with + or the multiplication sign
must be taken automatically as commutative and associative, until
Hamilton developed an algebra in which it was not so).

For now, the repair is left as an exercise for the future. */

/* If parent is not guaranteed acyclic, owing to the gap just
mentioned, perhaps we should check to make sure that the ch relation
is acyclic, just in case. */

assert ch_acyclic {
  no n : Node | n in n.^ch
}
check ch_acyclic for 5
// Oops.  Bad news, that.

/* What else could go wrong?  Well, we haven't yet checked to see
whether 'precedes' gives us a total ordering.  (If an element can be
among its own descendants, we can already guess the answer, but let's
formulate an explicit test.)  So let us assert that the ordering is
total.  */

assert total_order {
  all a, b : Node | a = b or full_precedes[a,b] or full_precedes[b,a]
}
check total_order for 5
/* And since precedes is intended to model <, not <=, we should have
this, too: */
assert precedes_unique {
  all a, b : Node | not (full_precedes[a,b] and full_precedes[b,a])
}
check precedes_unique for 5

/* And now that we do check, we discover that the definition of
precedes is faulty: to keep things analysable, Alloy prohibits
recursive definitions of predicates.  So we'll need to come back to
that. */

// Two documents (to illustrate that documents don't share)
pred two_doc {
  #Root = 2
}
run two_doc for 7
// Assert that two documents don't share; seek counterexamples.
assert docs_disjoint {
  all disj r, s : Root | no ( r.^(ch + atts) & s.^(ch + atts) )
}
check docs_disjoint for 7
// Alternative formulation of assertion
assert docs_disjoint2 {
  all r, s : Root | all n : Node |
    (r in n.*parent and s in n.*parent)
    implies r = s
}
check docs_disjoint2 for 7

/* In describing work with an automatic analysis tool, the creator of
Alloy writes [Jackson 2006, p. xiii]:

    The experience of exploring a software model with an automatic
    analyzer is at once thrilling and humiliating.  Most modelers have
    had the benefit of review by colleagues; it's a sure way to find
    flaws and catch omissions. Few modelers, however, have had the
    experience of subjecting their models to continual, automatic
    review.  Building a model incrementally with an analyzer,
    simulating and checking as you go along, is a very different
    experience from using pencil and paper alone.  The first reaction
    tends to be amazement,: modeling is much more fun when you get
    instant, visual feedback.  When you simulate a partial model, you
    see examples immediately that suggest new constraints to be added.

    Then the sense of humiliation sets in, as you discover that
    there's almost nothing you can do right.  What you write down
    doesn't mean exactly what you think it means.  And when it does,
    it doesn't have the consequences you expected.  Automatic analysis
    tools are far more ruthless than human reviewers.  I now cringe at
    the thought of all the models I wrote (and even published) that
    were never analyzed, as I know how error-ridden they must be.
    Slowly but surely the tool teaches you to make fewer and fewer
    errors.

The application of this description to the case of this effort to
formalize the data model of XPath 1.0 is left as an exercise for the
reader.

 */

/****************************************************************
References
****************************************************************/

/*

Jackson 2006

    Daniel Jackson, Software Abstractions: Logic, Language, and
    Analysis (Cambridge, Mass.: MIT Press, 2006).

    The Alloy system is also described in tutorials available on the
    Alloy Web site, <http://alloy.mit.edu/>.

W3C 1999

    World Wide Web Consortium (W3C), XML Path Language (XPath) Version
    1.0, W3C Recommendation 16 November 1999, ed. James Clark and
    Steve DeRose ([Cambridge (Mass.), Sophia-Antipolis, Tokyo]: W3C,
    1999).

    The version cited is available on the Web at
    <http://www.w3.org/TR/1999/REC-xpath-19991116/>; the latest
    version of the spec, reflecting all updates and corrections, is
    available at <http://www.w3.org/TR/xpath>.

W3C 2004 

    World Wide Web Consortium (W3C), XML Information Set (Second
    Edition), W3C Recommendation 4 February 2004, ed. John Cowan and
    Richard Tobin ([Cambridge (Mass.), Sophia-Antipolis, Tokyo]: W3C,
    2004).

    The version cited is available on the Web at
    <http://www.w3.org/TR/2004/REC-xml-infoset-20040204/>; the latest
    version of the spec, reflecting all updates and corrections, is
    available at <http://www.w3.org/TR/xml-infoset>.

W3C 2008

    World Wide Web Consortium (W3C), Extensible Markup Language (XML)
    1.0 (Fifth Edition), W3C Recommendation 26 November 2008, ed. Tim
    Bray et al. ([Cambridge (Mass.), Sophia-Antipolis, Tokyo]: W3C,
    2008).

    The version cited is available on the Web at
    <http://www.w3.org/TR/2008/REC-xml-20081126/>; the latest version
    of the spec, reflecting all updates and corrections, is available
    at <http://www.w3.org/TR/xml/>.

W3C 2009

    World Wide Web Consortium (W3C), Namespaces in XML 1.0 (Third
    Edition), W3C Recommendation 8 December 2009 ed. Tim Bray et
    al. ([Cambridge (Mass.), Sophia-Antipolis, Tokyo]: W3C, 2009).

    The version cited is available on the Web at
    <http://www.w3.org/TR/2009/REC-xml-names-20091208/>; the latest
    version of the spec, reflecting all updates and corrections, is
    available at <http://www.w3.org/TR/xml-names/>.

    
*/
/* To do:
- Fix parent relation; it should be the inverse of (ch+atts+ns).

- Ensure that parent and ch are acyclic.

- Integrate namespace nodes in at least a rudimentary way.

- Fix document order definition to eliminate recursion.

- Model maximal-textnode (no adjacent textnode) rule.

- Extend to define relations among string values?  Pro:  makes the
  model more complete.  Con:  makes the model larger and more 
  cumbersome, clarifies nothing (string values are already pretty
  clear, no?)

- Elaborate QNames more fully?

- Model the details of namespace nodes and their inheritance.
  This would also allow the modeling of namespace-wellformedness.

- Pair this model with a similar model based on the XML Infoset;
  check correspondences and differences between them.

- Pair this model with a separate definition of the semantics of
  XPath 1.0 expressions?
*/

/* Revision history:

18 March 2010: Add clauses to 'basic_precedes' predicate to cover
                  the rules saying NSNodes precede Attributes precede
                  children.

28 January 2010: Add nss property to Element (but don't model
                  NSNode propagation).  Add value property to Attribute.

26 January 2010:  Tweak some wording, correct some typos.
                  Publish model.

24 January 2010:  Add to-do list.  Work through Attribute, PI,
                  Comment, and Textnode.  Decide not to elaborate
                  NSNode.  Discover that parent and ch are not yet
                  guaranteed acyclic.  Discover that the defintion of
                  'precedes' must be rewored to avoid recursion.

23 January 2010:  Elaborate the prose comments to make the model more
                  accessible to non-Alloy users, and to introduce the
                  prose-formalism redundancy recommended by Z experts.
                  Move draft (still incomplete) to Web server.

20 January 2010:  Blog about sibling-identity issue.

19 January 2010:  Begin Alloy formalization of XPath 1.0 data model,
                  discover that the model does not by itself guarantee 
                  that ./preceding-sibling[1] is unique.

*/

