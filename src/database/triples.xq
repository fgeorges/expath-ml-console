xquery version "3.0";

import module namespace dbc = "http://expath.org/ns/ml/console/database/config" at "db-config-lib.xqy";

import module namespace a       = "http://expath.org/ns/ml/console/admin"   at "../lib/admin.xqy";
import module namespace t       = "http://expath.org/ns/ml/console/tools"   at "../lib/tools.xqy";
import module namespace triples = "http://expath.org/ns/ml/console/triples" at "../lib/triples.xqy";
import module namespace v       = "http://expath.org/ns/ml/console/view"    at "../lib/view.xqy";
import module namespace sem     = "http://marklogic.com/semantics" at "/MarkLogic/semantics.xqy";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare namespace c    = "http://expath.org/ns/ml/console";
declare namespace h    = "http://www.w3.org/1999/xhtml";
declare namespace cts  = "http://marklogic.com/cts";
declare namespace xdmp = "http://marklogic.com/xdmp";
declare namespace map  = "http://marklogic.com/xdmp/map";

(: Page to display triples from a database.  Can be called with:
 :
 : 1) /db/{id}/triples?rsrc=...       - display details of the resource with the given IRI
 : 2) /db/{id}/triples/...            - display details of the resource with the given CURIE
 : 3) /db/{id}/triples?init-curie=... - redirect to 2)
 : 4) /db/{id}/triples                - display the list of resources
 :
 : The token "trible" below (and in emlc-browser.js) stands from "triple table", a table
 : displaying triples.
 :)

(: Fixed page size for now. :)
declare variable $page-size := 100;

(:~
 : The overall page function.
 :)
declare function local:page(
   $db    as element(a:database),
   $start as xs:integer,
   $rsrc  as xs:string?,
   $curie as xs:string?,
   $init  as xs:string?,
   $rules as xs:string*,
   $decls as element(c:decl)*
) as element()+
{
   if ( fn:exists($rsrc) ) then (
      local:page--rsrc($db, $rsrc, './', $rules, $decls)
   )
   else if ( fn:exists($curie) ) then (
      local:page--rsrc($db, triples:expand($curie, $decls), '../', $rules, $decls)
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
 : The page content, when browsing resource list.
 :)
declare function local:page--browse($db as element(a:database), $start as xs:integer, $decls as element(c:decl)*)
   as element()+
{
   <p>Database: { $db/a:name ! v:db-link('../' || ., .) }</p>,
   <p> {
      let $query :=
            'SELECT DISTINCT ?s WHERE {
                ?s ?p ?o .
                # filter out blank nodes, and xs:dateTimes like in the Meters database
                FILTER ( isIRI(?s) )
             }
             ORDER BY ?s
             OFFSET $start
             LIMIT  $size'
      let $res   := sem:sparql($query, map:new((
                       map:entry('start', $start - 1),
                       map:entry('size',  $page-size))))
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
 : The page content, when displaying resource details.
 :
 : @todo Configurize the rule sets to use...
 :)
declare function local:page--rsrc(
   $db    as element(a:database),
   $rsrc  as xs:string,
   $root  as xs:string,
   $rules as xs:string*,
   $decls as element(c:decl)*
) as element()+
{
   <p> {
      $db/a:name ! v:db-link($root || '../' || ., .),
      text { ' ' },
      v:rsrc-link($root || 'triples', $rsrc, $decls)
   }
   </p>,

   (: TODO: Add a summary here, with some infos like rdfs:label, rdf:type, etc. :)

   <h3>Triples</h3>,
   <div id="out-loading" class="loading"/>,
   <div id="out-message" style="display: none" class="alert alert-dismissible fade" role="alert">
      <strong/>: <span/><br/>
      <em>Please report this, including the stacktrace from your browser JavaScript console.</em>
      <button type="button" class="close" data-dismiss="alert" aria-label="Close">
         <span aria-hidden="true">&#215;</span>
      </button>
   </div>,
   <table class="table table-compact trible-fillin" style="display: none"
      data-trible-subject="{ $rsrc }"
      data-trible-db="{ $db/a:name }"
      data-trible-rules="{ fn:string-join($rules, ',') }"
      data-trible-root="{ $root }"
      data-trible-loading="out-loading"
      data-trible-message="out-message"/>,

   <h3>Inbound triples</h3>,
   <div id="in-loading" class="loading"/>,
   <div id="in-message" style="display: none" class="alert alert-dismissible fade" role="alert">
      <strong/>: <span/><br/>
      <em>Please report this, including the stacktrace from your browser JavaScript console.</em>
      <button type="button" class="close" data-dismiss="alert" aria-label="Close">
         <span aria-hidden="true">&#215;</span>
      </button>
   </div>,
   <table class="table table-compact trible-fillin" style="display: none"
      data-trible-object="{ $rsrc }"
      data-trible-db="{ $db/a:name }"
      data-trible-rules="{ fn:string-join($rules, ',') }"
      data-trible-root="{ $root }"
      data-trible-loading="in-loading"
      data-trible-message="in-message"/>,

   <h3>Rulesets</h3>,
   <p>The following rulesets have been used to query the triples shown on this page:</p>,
   <ul> {
      if ( fn:empty($rules) ) then
         <li><em>no ruleset</em></li>
      else
         for $r in $rules
         order by $r
         return
            <li>{ $r }</li>
   }
   </ul>,
   <p>Change the rulesets to use below:</p>,
   v:form($root || 'triples', (), (
      v:input-hidden('rsrc', $rsrc),
      v:input-select-rulesets('rulesets', 'Rulesets', $rules),
      v:submit('Reload')),
      'get'),

   <h3>Documents</h3>,
   let $uris := cts:uris('', (), cts:and-query(cts:triple-range-query(sem:iri($rsrc), (), ())))
   return
      if ( fn:empty($uris) ) then
         <p>The triples with this subject are only the result of inference.</p>
      else (
         <p>The triples with this subject originate from the following
            document{ 's'[fn:count($uris) gt 1] }:</p>,
         <ul> {
            for $uri in $uris
            order by $uri
            return
               <li>{ v:doc-link($root, $uri) }</li>
         }
         </ul>
      )
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
   else if ( sem:isBlank($val) ) then
      if ( $kind eq 'rsrc' ) then
         v:blank-link($root || 'triples', $val, $decls)
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
      <span class="fa fa-link" title="Resource"/>
   else if ( sem:isBlank($v) ) then
      <span class="fa fa-bars" title="Blank node"/>
   else if ( sem:isNumeric($v) ) then
      <span class="fa fa-usd" title="Number"/>
   else if ( sem:lang($v) ) then
      sem:lang($v) ! <span class="fa fa-font" title="String, language: { . }">&#160;{ . }</span>
   else if ( $v instance of xs:date or $v instance of xs:dateTime ) then
      <span class="fa fa-hourglass" title="Date"/>
   else
      (: Assuming a string? :)
      <span class="fa fa-font" title="String"/>
};

let $name  := t:mandatory-field('name')
let $rsrc  := t:optional-field('rsrc', ())
let $curie := t:optional-field('curie', ())
let $init  := t:optional-field('init-curie', ())
let $start := xs:integer(t:optional-field('start', 1)[.])
let $rules := t:optional-field('rulesets', ())[.] ! fn:tokenize(., '\s*,\s*')[.]
let $root  := '../../' || '../'[$curie]
return
   v:console-page(
      $root,
      'browser',
      'Browse resources',
      function() {
         v:ensure-db($name, function($db) {
            let $decls := dbc:config-triple-prefixes($db)
            return
               v:ensure-triple-index($db, function() {
                  t:query($db, function() {
                     local:page($db, $start, $rsrc, $curie, $init, $rules, $decls)
                  })
               })
         })
      },
      <lib>emlc.trible</lib>)
