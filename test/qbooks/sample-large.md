# Simple qbook

Simple example of a qbook, with simple use cases.

Qbooks use the GitHub flavour of Markdown to detect the language of a code
block.  A code block is delimited by lines with 3 backticks (or 3 tildes `~`).
The name after the first line of backticks (or tildes) is the name of the
language for that code.

And before starting, just to validate that images work as well:
![test image](../../src/images/expath-icon.png "Some test logo")

Table of content:

- [Query detection](#query-detection)
- [Result format and links](#result-format-and-links)
- [SPARQL](#sparql)
- [Parameters](#parameters)

## Query detection

The queries are simple code blocks, with the language `js`, `sjs` or
`javascript` for JavaScript, and `xqy` or `xquery` for XQuery.  For instance:

~~~no-highlight
```xqy
fn:string-join(('Hello', 'world!'), ', ')
```
~~~

This code has no language, so must not be an executable query, but language is
"guessed" for highlighting:

```
fn:string-join(('Hello', 'world!'), ', ')
```

This code uses an unknown language, so must not be an executable query either,
but language must not be "guessed":

```no-highlight
fn:string-join(('Hello', 'world!'), ', ')
```

This code uses `js`:

```js
['Hello', 'world!'].join(', ');
```

This code uses `sjs`:

```sjs
['Hello', 'world!'].join(', ');
```

This code uses `javascript`:

```javascript
['Hello', 'world!'].join(', ');
```

This code uses `xqy`:

```xqy
fn:string-join(('Hello', 'world!'), ', ')
```

This code uses `xquery`:

```xquery
fn:string-join(('Hello', 'world!'), ', ')
```

## Result format and links

These queries present a few examples of result formatting, depending on the type
of the result.  The `xs:anyURI` become links to documents, and `sem:iri` become
links to resources (both URI and IRI in the content database used for
evaluation).

Sequence of simple items of different types:

```xquery
'string', 42, 42.0, 42.42, xs:date('1979-09-01'), xs:dateTime('2019-05-05T22:08:00')
```

Link to document:

```xquery
declare namespace sw = "http://h2o.consulting/ns/star-wars";
/sw:people[sw:name eq 'Han Solo'] => fn:root() => fn:document-uri()
```

```javascript
const res = sem.sparql(`
    PREFIX rdf:  <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
    PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
    PREFIX sw:   <http://h2o.consulting/ns/star-wars#>
    SELECT * WHERE {
        ?han  rdf:type    sw:People .
        ?han  rdfs:label  'Han Solo' .
    }`);
fn.head(res).han;
```

## SPARQL

Some notes about built-in SPARQL support (not there yet):

```sparql
PREFIX rdf:  <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX sw:   <http://h2o.consulting/ns/star-wars#>
SELECT * WHERE {
    ?han  rdf:type    sw:People .
    ?han  rdfs:label  'Han Solo' .
}
```

```javascript
//! @result: table
sem.sparql(`
    PREFIX rdf:  <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
    PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
    PREFIX sw:   <http://h2o.consulting/ns/star-wars#>
    SELECT * WHERE {
        ?han  rdf:type    sw:People .
        ?han  rdfs:label  'Han Solo' .
    }`);
```

```xquery
(:! @result: table :)
sem:sparql("
    PREFIX rdf:  <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
    PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
    PREFIX sw:   <http://h2o.consulting/ns/star-wars#>
    SELECT * WHERE {
        ?han  rdf:type    sw:People .
        ?han  rdfs:label  'Han Solo' .
    }")
```

## Parameters

Parameters in XQuery need to be declared:

```xqy
declare namespace ns = "some/ns";
declare variable $foo external;
declare variable $bar as xs:date? external;
declare variable $ns:foo external;
declare variable $ns:bar as sem:iri external;

fn:string-join(($foo, $ns:foo, $ns:bar), ' - ') || ': ' || $bar
```

For JavaScript, parameters are declared using a special comment.  Whether it
starts with `//` or `/*`, the first characters need to be `!`, and then the
keyword `@params` is followed by space-separated variable names:

**TODO**: Support the new `//!` format.

```sjs
//! @params foo bar
`${foo} - ${bar}`
```
