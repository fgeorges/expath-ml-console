xquery version "3.0";

import module namespace a   = "http://expath.org/ns/ml/console/admin" at "../lib/admin.xql";
import module namespace t   = "http://expath.org/ns/ml/console/tools" at "../lib/tools.xql";
import module namespace v   = "http://expath.org/ns/ml/console/view"  at "../lib/view.xql";
import module namespace sem = "http://marklogic.com/semantics" at "/MarkLogic/semantics.xqy";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare namespace c   = "http://expath.org/ns/ml/console";
declare namespace h   = "http://www.w3.org/1999/xhtml";
declare namespace cts = "http://marklogic.com/cts";
declare namespace map = "http://marklogic.com/xdmp/map";

(: Fixed page size for now. :)
declare variable $page-size := 100;

(:~
 : The overall page function.
 :)
declare function local:page(
   $name  as xs:string,
   $start as xs:integer,
   $rsrc  as xs:string?,
   $curie as xs:string?,
   $init  as xs:string?,
   $decls as element(c:decl)*
) as element()+
{
   let $db := a:get-database($name)
   return
      (: TODO: In this case, we should return "404 Not found". :)
      if ( fn:empty($db) ) then (
         local:page--no-db($name)
      )
      else if ( fn:exists($rsrc) ) then (
         local:page--rsrc($db, $rsrc, './', $decls)
      )
      else if ( fn:exists($curie) ) then (
         local:page--rsrc($db, v:expand-curie($curie, $decls), '../', $decls)
      )
      else if ( fn:exists($init) ) then (
         local:page--init-curie($init)
      )
      else (
         local:page--browse($db, $start, $decls)
      )
};

declare function local:page--init-curie($init as xs:string)
   as element(h:p)
{
   v:redirect('triples/' || $init),
   <p>You are being redirected to <a href="triples/{ $init }">this page</a>...</p>
};

(:~
 : The page content, in case the DB does not exist.
 :)
declare function local:page--no-db($name as xs:string)
   as element(h:p)
{
   <p><b>Error</b>: The database "<code>{ $name }</code>" does not exist.</p>
};

(:~
 : The page content, when browsing resource list.
 :)
declare function local:page--browse($db as element(a:database), $start as xs:integer, $decls as element(c:decl)*)
   as element()+
{
   <p>Database: { $db/a:name ! v:db-link('../' || ., .) }</p>,
   <p> {
      (: TODO: Pass parameters properly, instead of concatenating values. :)
      let $query :=
            'SELECT DISTINCT ?s WHERE {
                ?s ?p ?o .
                # filter out blank nodes, and xs:dateTimes like in the Meters database
                FILTER ( isIRI(?s) )
             }
             ORDER BY ?s
             OFFSET ' || $start - 1 || '
             LIMIT ' || $page-size
      let $res   := sem:sparql($query)
      let $count := fn:count($res)
      let $to    := $start + $count - 1
      return (
         'Results ' || $start || ' to ' || $to,
         t:when($start gt 1,
            (', ', <a href="triples?start={ $start - $page-size }">previous page</a>)),
         t:when($count eq $page-size,
            (', ', <a href="triples?start={ $start + $count }">next page</a>)),
         ':',
         $res ! map:get(., 's')
            ! <li>{ v:rsrc-link('triples', ., $decls) }</li>
      )
   }
   </p>
};

(:~
 : The page content, when browsing resource list.
 :
 : @todo Configurize the rule sets to use...
 :)
declare function local:page--rsrc(
   $db    as element(a:database),
   $rsrc  as xs:string,
   $root  as xs:string,
   $decls as element(c:decl)*
) as element()+
{
   <p>Database: { $db/a:name ! v:db-link($root || '../' || ., .) }</p>,
   <p>Resource: { v:rsrc-link($root || 'triples', $rsrc, $decls) }</p>,
   <h3>Triples</h3>,
   <table class="table table-striped datatable">
      <thead>
         <th>Property</th>
         <th>Object</th>
         <th>Type</th>
      </thead>
      <tbody> {
         (: TODO: Support windowing, in case one single resources has thousands of triples. :)
         for $r in sem:sparql(
                      'SELECT ?p ?o WHERE { ?s ?p ?o } ORDER BY ?p',
                      map:entry('s', sem:iri($rsrc)),
                      (),
                      (: TODO: For temporal documents, should be sem:store((), cts:collection-query('latest')) :)
                      sem:ruleset-store('rdfs.rules', sem:store()))
         return
            <tr>
               <td>{ local:display-value(map:get($r, 'p'), 'prop', $root, $decls) }</td>
               <td>{ local:display-value(map:get($r, 'o'), 'rsrc', $root, $decls) }</td>
               <td>{ local:display-type(map:get($r, 'o')) }</td>
            </tr>
      }
      </tbody>
   </table>,
   <h3>Inbound links</h3>,
   <table class="table table-striped datatable">
      <thead>
         <th>Subject</th>
         <th>Property</th>
      </thead>
      <tbody> {
         (: TODO: Support windowing, in case one single resources has thousands of links. :)
         for $r in sem:sparql(
                      'SELECT ?s ?p WHERE { ?s ?p ?o } ORDER BY ?p',
                      map:entry('o', sem:iri($rsrc)),
                      (),
                      (: TODO: For temporal documents, should be sem:store((), cts:collection-query('latest')) :)
                      sem:ruleset-store('rdfs.rules', sem:store()))
         return
            <tr>
               <td>{ local:display-value(map:get($r, 's'), 'rsrc', $root, $decls) }</td>
               <td>{ local:display-value(map:get($r, 'p'), 'prop', $root, $decls) }</td>
            </tr>
      }
      </tbody>
   </table>,
   <h3>Documents</h3>,
   <p>The triples with this subject (those stored, not inferred), are stored in the
      following document(s):</p>,
   <ul> {
      let $uris := cts:uris('', (), cts:and-query(cts:triple-range-query(sem:iri($rsrc), (), ())))
      return
         if ( fn:empty($uris) ) then
            <li><em>no triple stored in document</em></li>
         else
            for $uri in $uris
            order by $uri
            return
               <li>{ v:doc-link($root, $uri) }</li>
   }
   </ul>
};

declare function local:display-value(
   $val   as xs:anyAtomicType,
   $kind  as xs:string,
   $root  as xs:string,
   $decls as element(c:decl)*
) as element()
{
   if ( sem:isIRI($val) ) then
      (: TODO: Display the link only when the resource exists (that is, there is
         at least one triple with that IRI as subject). :)
      if ( $kind eq 'rsrc' ) then
         v:rsrc-link($root || 'triples', $val, $decls)
      else if ( $kind eq 'prop' ) then
         v:prop-link($root || 'triples', $val, $decls)
      else
         t:error('internal', 'Unexpected error - Unkown kind: ' || $kind)
   else
      <span>{ $val }</span>
};

declare function local:display-type($v as xs:anyAtomicType)
   as element()
{
   (: TODO: Return a different class instead per case, and display it graphically
      rather than using a string. :)
   if ( sem:isIRI($v) ) then
      <span class="glyphicon glyphicon-link" title="Resource"/>
   else if ( sem:isNumeric($v) ) then
      <span class="glyphicon glyphicon-usd"  title="Number"/>
   else if ( sem:lang($v) ) then
      sem:lang($v) ! <span class="glyphicon glyphicon-font" title="String, language: { . }">&#160;{ . }</span>
   else
      (: Assuming a string? :)
      <span class="glyphicon glyphicon-font" title="String"/>
};

let $db    := t:mandatory-field('name')
let $rsrc  := t:optional-field('rsrc', ())
let $curie := t:optional-field('curie', ())
let $init  := t:optional-field('init-curie', ())
let $start := xs:integer(t:optional-field('start', 1)[.])
let $root  := '../../' || '../'[$curie]
let $decls := t:config-triple-prefixes($db)
return
   v:console-page($root, 'browser', 'Browse resources', function() {
      t:query($db, function() {
         local:page($db, $start, $rsrc, $curie, $init, $decls)
      })
   })
