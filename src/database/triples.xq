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
      local:page--init-curie($init, $rules)
   )
   else (
      local:page--browse($db, $start, $decls)
   )
};

declare function local:page--init-curie($init as xs:string, $rules as xs:string*)
   as element(h:p)
{
   let $param := if ( fn:exists($rules) ) then '?rulesets=' || fn:string-join($rules, ',') else ()
   let $url   := 'triples/' || $init || $param
   return (
      v:redirect($url),
      <p>You are being redirected to <a href="{ $url }">this page</a>...</p>
   )
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

   <h3>Summary</h3>,
   <p/>,
   <table id="summary" class="table table-bordered">
      <tbody>
         <tr><th>IRI</th><td><code>{ $rsrc }</code></td></tr>
         {
           let $curie := triples:curie($rsrc, $decls)
           return
              if ( $curie ) then
                 <tr><th>CURIE</th><td><code>{ $curie }</code></td></tr>
              else
                 triples:abbreviate($rsrc, ())[fn:not(. eq $rsrc)]
                 ! <tr><th>Abbrev</th><td><code>{ . }</code></td></tr>
         }
      </tbody>
   </table>,

   <h3>Graph</h3>,
   <p/>,
   <div id="triph-loading" class="loading"/>,
   <div id="triph-tooltip" class="triph-tooltip"/>,
   <svg id="triph" class="triph" data-trible-loading="#triph-loading" data-trible-root="{ $root }">
      <g id="triph-links"/>
      <g id="triph-nodes"/>
   </svg>,

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
      data-trible-loading="#out-loading"
      data-trible-message="#out-message"/>,

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
      data-trible-loading="#in-loading"
      data-trible-message="#in-message"/>,

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
   let $uris := cts:uris('', (), cts:triple-range-query(sem:iri($rsrc), (), ()))
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
