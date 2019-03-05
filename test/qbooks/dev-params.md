# Simple qbook

Comprehensive set of examples using parameters, for development purposes.

Table of content:

- [JavaScript](#javascript)
- [SPARQL](#sparql)
- [XQuery](#xquery)

## JavaScript

For JavaScript, parameters are declared using a special comment.  Whether it
starts with `//` or `/*`, the first characters need to be `!`, and then the
keyword `@params` is followed by space-separated variable names.  The `@params`
declaration goes till the end of the line (or `*/` if any.)  There can be only
one `@params` declaration in the query.

**TODO**: Support the new `//!` format.

Using `//!`:

```sjs
//! @params foo bar
`${foo} - ${bar}`
```

Or using `/*!`:

```sjs
/*!
 * @params foo bar
 */
`${foo} - ${bar}`
```

Parameters can also be declared individually, especially to be able to add more
info, besides their name (e.g. their type).  Use `@param` instead, only one per
line.

Using `//!`:

```sjs
//! @param foo
//! @param bar
`${foo} - ${bar}`
```

Or using `/*!`:

```sjs
/*!
 * @param foo
 * @param bar
 */
`${foo} - ${bar}`
```

## SPARQL

**TODO**: SPARQL not supported yet.

## XQuery

Parameters in XQuery need to be declared (as external variables):

```xqy
declare namespace ns = "some/ns";
declare variable $param    external;
declare variable $ns:param external;
declare variable $var      := 'foo';
declare variable $ns:var   := sem:iri('bar');

fn:string-join(($param, $ns:param, $var, $ns:var) ! xs:string(.), ' - ')
```

**TODO**: Parameters with an explicit type declaration (`xs:*`, `sem:*` and node
kinds):

```xqy
declare namespace ns = "some/ns";
declare variable $witness    as xs:integer external;
declare variable $ns:witness as xs:integer external;

declare variable $one   as xs:date         external;
declare variable $two   as xs:anyURI       external;
declare variable $three as sem:iri         external;
declare variable $four  as item()          external;
declare variable $five  as binary()        external;
declare variable $six   as document-node() external;

fn:string-join(($witness, $ns:winess, $one, $two, $three, $four, $five, $six) ! xs:string(.), ' - ')
```

**TODO**: Load a file:

```xqy
(:!
 : @param $one    select:file
 : @param $two    select:file
 : @param $three  select:file
 : @param $four   select:file
 : @param $five   select:file
 : @param $six    select:file
 : @param $seven  select:file
 : @param $height select:file
 : @param $nine   select:file
 :)
declare namespace ns = "some/ns";
declare variable $one    as element()       external;
declare variable $two    as text()          external;
declare variable $three  as binary()        external;
declare variable $four   as xs:string       external;
declare variable $five   as xs:base64Binary external;
declare variable $six    as element()       external;
declare variable $seven  as document-node() external;
declare variable $height as object-node()   external;
declare variable $nine   as array-node()    external;

fn:count(($one, $two, $three, $four, $five))
```

**TODO**: Parameters with occurrence indication:

```
...
```

**TODO**: Params with default values not parsed properly:

```xqy
declare namespace ns = "some/ns";
declare variable $param    external := 'foo';
declare variable $ns:param external := sem:iri('bar');
declare variable $typed    as xs:string external := 'foo';
declare variable $ns:typed as sem:iri   external := sem:iri('bar');

fn:string-join(($param, $ns:param, $typed, $ns:typed) ! xs:string(.), ' - ')
```

**TODO**: Parameter types with other prefixes than `xs` and `sem` (as well as
other URI bound to `xs` and `sem`, and `xs` and `sem` URI bound to other
prefixes.)

```
...
```
