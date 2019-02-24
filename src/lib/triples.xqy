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

declare function this:rdf($name as xs:string) as xs:string {
  $this:rdfs-uri || $name
};

declare function this:rdfs($name as xs:string) as xs:string {
  $this:rdfs-uri || $name
};

declare function this:xs($name as xs:string) as xs:string {
  $this:xs-uri || $name
};

declare function this:curie($iri as xs:string) as xs:string? {
  this:curie($iri, dbc:config-triple-prefixes(xdmp:database()))
};

(:~
 : Shorten a resource IRI to a CURIE, if a prefix can be found for it.
 :
 : The first entry in `$decls` that matches $iri (that is, the first one for which
 : $iri starts with the text value of) is used.  If there is no such entry, return
 : the empty sequence.
 :)
declare function this:curie($iri as xs:string, $decls as element(c:decl)*)
   as xs:string?
{
   this:find-prefix-by-iri($iri, $decls)
      ! ( c:prefix || ':' || fn:substring-after($iri, c:uri) )
};

declare function this:expand($curie as xs:string) as xs:string? {
  this:expand($curie, dbc:config-triple-prefixes(xdmp:database()))
};

(:~
 : Expand a CURIE notation to the full IRI.
 :
 : The first entry in `$decls` that matches the prefix of the CURIE is used.  If
 : there is no such entry, the function returns the empty sequence.
 :)
declare function this:expand($curie as xs:string, $decls as element(c:decl)*)
   as xs:string?
{
   fn:substring-before($curie, ':')[.]
   ! this:find-prefix-by-prefix(., $decls)
   ! (c:uri || fn:substring-after($curie, ':'))
};

(:~
 : Return the first matching prefix declaration, for a complete resource IRI.
 :)
declare function this:find-prefix-by-iri($iri as xs:string, $decls as element(c:decl)*)
   as element(c:decl)?
{
   this:find-matching-prefix($decls, function($decl) {
      fn:starts-with($iri, $decl/c:uri)
   })
};

(:~
 : Return the first matching prefix declaration, for a given prefix.
 :)
declare function this:find-prefix-by-prefix($prefix as xs:string, $decls as element(c:decl)*)
   as element(c:decl)?
{
   this:find-matching-prefix($decls, function($decl) {
      $decl/c:prefix eq $prefix
   })
};

(:~
 : Return the first matching prefix declaration, for a given predicate.
 :)
declare function this:find-matching-prefix(
   $decls as element(c:decl)*,
   $pred  as function(element(c:decl)) as xs:boolean
) as element(c:decl)?
{
   if ( fn:empty($decls) ) then
      ()
   else if ( $pred($decls[1]) ) then
      $decls[1]
   else
      this:find-matching-prefix(fn:remove($decls, 1), $pred)
};
