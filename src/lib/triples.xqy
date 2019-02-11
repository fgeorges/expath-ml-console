xquery version "3.1";

module namespace this = "http://expath.org/ns/ml/console/triples";

import module namespace dbc = "http://expath.org/ns/ml/console/database/config"
  at "/database/db-config-lib.xqy";

declare namespace c    = "http://expath.org/ns/ml/console";
declare namespace sem  = "http://marklogic.com/semantics";
declare namespace map  = "http://marklogic.com/xdmp/map";
declare namespace xdmp = "http://marklogic.com/xdmp";

declare variable $this:rdf-uri  := 'http://www.w3.org/1999/02/22-rdf-syntax-ns#';
declare variable $this:rdfs-uri := 'http://www.w3.org/2000/01/rdf-schema#';
declare variable $this:xs-uri   := 'http://www.w3.org/2001/XMLSchema#';

declare function this:sparql($query as xs:string) as item()* {
  this:sparql($query, ())
};

declare function this:sparql($query as xs:string, $params as map:map?) as item()* {
  this:sparql($query, $params, ())
};

declare function this:sparql(
  $query  as xs:string,
  $params as map:map?,
  $store  as sem:store?
) as item()*
{
  this:sparql($query, $params, $store, ())
};

declare function this:sparql(
  $query   as xs:string,
  $params  as map:map?,
  $store   as sem:store?,
  $options as xs:string*
) as item()*
{
  this:sparql($query, $params, $store, $options, dbc:config-triple-prefixes(xdmp:database()))
};

declare function this:sparql(
  $query    as xs:string,
  $params   as map:map?,
  $store    as sem:store?,
  $options  as xs:string*,
  $prefixes as element(c:decl)*
) as item()*
{
  sem:sparql(
    fn:string-join((
      fn:string-join(
        $prefixes ! ('PREFIX ' || @prefix || ':  <' || @uri || '>'), '&#10;'),
      $query),
      '&#10;&#10;'),
    $params,
    $options,
    $store)
};

declare function this:curie($iri as xs:string) as xs:string? {
  this:curie($iri, dbc:config-triple-prefixes(xdmp:database()))
};

declare function this:curie(
  $iri      as xs:string,
  $prefixes as element(c:decl)*
) as xs:string?
{
  let $local := fn:substring-after($iri, '#')[.]
  return
    if ( fn:empty($local) ) then
      fn:error((), 'No hash character in IRI: ' || $iri)
    else
      let $uri    := fn:substring-before($iri, '#') || '#'
      let $prefix := $prefixes[c:uri eq $uri]/c:prefix
      return
        $prefix ! (. || ':' || $local)
};

declare function this:expand($curie as xs:string) as xs:string? {
  this:expand($curie, dbc:config-triple-prefixes(xdmp:database()))
};

declare function this:expand(
  $curie    as xs:string,
  $prefixes as element(c:decl)*
) as xs:string?
{
  let $local := fn:substring-after($curie, ':')
  return
    if ( fn:empty($local) ) then
      fn:error((), 'No colon character in CURIE: ' || $curie)
    else
      let $prefix := fn:substring-before($curie, ':')
      let $uri    := fn:zero-or-one($prefixes[c:prefix eq $prefix]/c:uri)
      return
        $uri ! (. || $local)
};

declare function this:rdf($name as xs:string) as xs:string {
  $this:rdfs-uri || $name
};

declare function this:rdfs($name as xs:string) as xs:string {
  $this:rdfs-uri || $name
};

declare function this:xs($name as xs:string) as xs:string {
  $this:xs-uri || $name
};
