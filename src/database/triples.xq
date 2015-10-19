xquery version "3.0";

import module namespace a   = "http://expath.org/ns/ml/console/admin" at "../lib/admin.xql";
import module namespace t   = "http://expath.org/ns/ml/console/tools" at "../lib/tools.xql";
import module namespace v   = "http://expath.org/ns/ml/console/view"  at "../lib/view.xql";
import module namespace sem = "http://marklogic.com/semantics" at "/MarkLogic/semantics.xqy";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare namespace h      = "http://www.w3.org/1999/xhtml";
declare namespace c      = "http://expath.org/ns/ml/console";
declare namespace err    = "http://www.w3.org/2005/xqt-errors";
declare namespace cts    = "http://marklogic.com/cts";
declare namespace xdmp   = "http://marklogic.com/xdmp";
declare namespace map    = "http://marklogic.com/xdmp/map";
declare namespace sec    = "http://marklogic.com/xdmp/security";
declare namespace sparql = "http://www.w3.org/2005/sparql-results#";

declare variable $path := local:get-param-path();

declare variable $root := local:get-root($path);

(: Fixed page size for now. :)
declare variable $page-size := 100;

(:~
 : The param "path", if any.
 :)
declare function local:get-param-path()
   as xs:string?
{
   let $path := t:optional-field('path', ())[.]
   return
      if ( fn:starts-with($path, '/http://') ) then
         fn:substring($path, 2)
      else
         $path
};

(:~
 : The path to the webapp root, relative to current $path.
 :)
declare function local:get-root($path as xs:string)
   as xs:string
{
   if ( fn:empty($path) ) then
      './'
   else
      let $toks  := fn:tokenize($path, '/')
      let $count := fn:count($toks) + (1[fn:starts-with($path, '/')], 2)[1]
      return
         t:make-string('../', $count)
};

(:~
 : The overall page function.
 :)
declare function local:page(
   $id    as xs:unsignedLong,
   $start as xs:integer,
   $rsrc  as xs:string?
) as element()+
{
   let $db := a:get-database($id)
   return
      (: TODO: In this case, we should NOT return "200 OK". :)
      if ( fn:empty($db) ) then (
         local:page--no-db($id)
      )
      else if ( fn:empty($rsrc) ) then (
         local:page--browse($db/a:name, $start)
      )
      else (
         local:page--rsrc($db/a:name, $rsrc)
      )
};

(:~
 : The page content, in case the DB does not exist.
 :)
declare function local:page--no-db($id as xs:unsignedLong)
   as element(h:p)
{
   <p><b>Error</b>: The database "<code>{ $id }</code>" does not exist.</p>
};

(:~
 : The page content, when browsing resource list.
 :)
declare function local:page--browse($db as xs:string, $start as xs:integer)
   as element()+
{
   <p>Database: "{ $db }".  Go up to <a href="../../tools">tools</a>.</p>,
   <p> {
      (: TODO: As it is, the query includes blank nodes. Filter them out! :)
      let $query :=
            'SELECT DISTINCT ?s WHERE {
                ?s ?p ?o .
                FILTER ( ! isBlank(?s) )
             }
             ORDER BY ?s
             OFFSET ' || $start - 1 || '
             LIMIT ' || $page-size
      let $res   := sem:sparql($query)
      let $count := fn:count($res)
      let $to    := $start + $count - 1
      return (
         'Results ' || $start || ' to ' || $to,
         t:cond($start gt 1,
            (', ', <a href="triples?start={ $start - $page-size }">previous page</a>)),
         t:cond($count eq $page-size,
            (', ', <a href="triples?start={ $start + $count }">next page</a>)),
         ':',
         $res ! map:get(., 's') ! <li><a href="triples?rsrc={ fn:encode-for-uri(.) }">{ . }</a></li>
      )
   }
   </p>
};

(:~
 : The page content, when browsing resource list.
 :)
declare function local:page--rsrc($db as xs:string, $rsrc as xs:string)
   as element()+
{
   <p>
      Database: "{ $db }".
      Go up to <a href="../../tools">tools</a>.
      Go back to <a href="triples">browse</a>.
   </p>,
   <p>Resource <code>{ $rsrc }</code>:</p>,
   <table class="table table-striped">
      <thead>
         <th>Property</th>
         <th>Object</th>
         <th>Type</th>
      </thead>
      <tbody> {
         (: TODO: Support windowing, in case one single resources has thousands of triples. :)
         let $query :=
               'SELECT ?p ?o WHERE {
                   <' || $rsrc || '> ?p ?o
                }
                ORDER BY ?p'
         for $r     in sem:sparql($query)
         return
            (: TODO: Abbreviate properties, based on configured prefixes (or well-known?) :)
            <tr>
               <td>{ local:display-value(map:get($r, 'p')) }</td>
               <td>{ local:display-value(map:get($r, 'o')) }</td>
               <td>{ local:display-type(map:get($r, 'o')) }</td>
            </tr>
      }
      </tbody>
   </table>
};

declare function local:display-value($v as xs:anyAtomicType)
   as element()
{
   if ( sem:isIRI($v) ) then
      (: TODO: Display the link only when the resource exists (that is, there is
         at least one triple with that IRI as subkect). :)
      <a href="triples?rsrc={ fn:encode-for-uri($v) }">{ $v }</a>
   else
      <span>{ $v }</span>
};

declare function local:display-type($v as xs:anyAtomicType)
   as element()
{
   (: TODO: Return a different class instead per case, and display it graphically
      rather than using a string. :)
   if ( sem:isIRI($v) ) then
      <span>IRI</span>
   else if ( sem:isNumeric($v) ) then
      <span>Num</span>
   else if ( sem:lang($v) ) then
      <span>Str ({ sem:lang($v) })</span>
   else
      (: Assuming a string? :)
      <span>Str</span>
};

let $slashes := if ( fn:empty($path) ) then 0 else fn:count(fn:tokenize($path, '/'))
let $root    := fn:string-join(for $i in 1 to $slashes + 2 return '..', '/') || '/'
let $db-str  := t:mandatory-field('id')
let $db      := xs:unsignedLong($db-str)
let $rsrc    := t:optional-field('rsrc', ())
let $start   := xs:integer(t:optional-field('start', 1)[.])
let $params  := 
      map:new((
         map:entry(xdmp:key-from-QName(fn:QName('', 'db')),   $db),
         map:entry(xdmp:key-from-QName(fn:QName('', 'rsrc')), $rsrc),
         map:entry(xdmp:key-from-QName(fn:QName('', 'start')), $start),
         map:entry(xdmp:key-from-QName(fn:QName('', 'fun')),  local:page#3)))
return
   v:console-page($root, 'tools', 'Browse triples', function() {
      a:eval-on-database(
         $db,
         'declare variable $db    external;
          declare variable $start external;
          declare variable $rsrc  external := ();
          declare variable $fun   external;
          $fun($db, $start, $rsrc)',
         $params)
   })
