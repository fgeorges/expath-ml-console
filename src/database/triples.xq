xquery version "3.0";

import module namespace dbc = "http://expath.org/ns/ml/console/database/config" at "db-config-lib.xql";

import module namespace a   = "http://expath.org/ns/ml/console/admin" at "../lib/admin.xqy";
import module namespace t   = "http://expath.org/ns/ml/console/tools" at "../lib/tools.xqy";
import module namespace v   = "http://expath.org/ns/ml/console/view"  at "../lib/view.xql";
import module namespace sem = "http://marklogic.com/semantics" at "/MarkLogic/semantics.xqy";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare namespace c    = "http://expath.org/ns/ml/console";
declare namespace h    = "http://www.w3.org/1999/xhtml";
declare namespace cts  = "http://marklogic.com/cts";
declare namespace xdmp = "http://marklogic.com/xdmp";
declare namespace map  = "http://marklogic.com/xdmp/map";

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
      local:page--rsrc($db, v:expand-curie($curie, $decls), '../', $rules, $decls)
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
   $rules as xs:string*,
   $decls as element(c:decl)*
) as element()+
{
   <p>Database: { $db/a:name ! v:db-link($root || '../' || ., .) }</p>,
   <p>Resource: { v:rsrc-link($root || 'triples', $rsrc, $decls) }</p>,

   <h3>Triples</h3>,
   local:subject-table($rsrc, $root, $rules, $decls, fn:true()),

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
                      sem:ruleset-store($rules, sem:store()))
         let $s := map:get($r, 's')
         let $p := map:get($r, 'p')
         return
            if ( sem:isBlank($s) ) then
               let $unik := xdmp:random()
               return (
                  <tr>
                     <td>
                        <span class="glyphicon glyphicon-collapse-down" id="expand{ $unik }"
                              title="Expand the blank node"
                              onclick="$('#table{ $unik }').slideToggle();
                                       $('#expand{ $unik }').toggle(); $('#collapse{ $unik }').toggle();"/>
                        <span class="glyphicon glyphicon-collapse-up"   id="collapse{ $unik }"
                              title="Collapse the blank node" style="display: none"
                              onclick="$('#table{ $unik }').slideToggle();
                                       $('#collapse{ $unik }').toggle(); $('#expand{ $unik }').toggle();"/>
                        { ' ' }
                        { local:display-value($s, 'rsrc', $root, $decls) }
                     </td>
                     <td rowspan="2"> {
                        local:display-value($p, 'prop', $root, $decls)
                     }
                     </td>
                  </tr>,
                  <tr>
                     <td id="table{ $unik }" style="display: none"> {
                        local:subject-table($s, $root, $rules, $decls, fn:false())
                     }
                     </td>
                  </tr>
               )
            else
               <tr>
                  <td>{ local:display-value($s, 'rsrc', $root, $decls) }</td>
                  <td>{ local:display-value($p, 'prop', $root, $decls) }</td>
               </tr>
      }
      </tbody>
   </table>,

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

declare function local:subject-table(
   $rsrc  as item(),
   $root  as xs:string,
   $rules as xs:string*,
   $decls as element(c:decl)*,
   $top   as xs:boolean
) as element(h:table)
{
   <table class="table table-striped datatable">
      {
         <thead>
            <th>Property</th>
            <th>Object</th>
            <th>Type</th>
         </thead>[$top]
      }
      <tbody> {
         (: TODO: Support windowing, in case one single resources has thousands of triples. :)
         for $r in sem:sparql(
                      'SELECT ?p ?o WHERE { ?s ?p ?o } ORDER BY ?p',
                      map:entry('s', sem:iri($rsrc)),
                      (),
                      (: TODO: For temporal documents, should be sem:store((), cts:collection-query('latest')) :)
                      sem:ruleset-store($rules, sem:store()))
         let $p := map:get($r, 'p')
         let $o := map:get($r, 'o')
         return
            if ( sem:isBlank($o) ) then
               let $unik := xdmp:random()
               return (
                  <tr>
                     <td rowspan="2">{ local:display-value($p, 'prop', $root, $decls) }</td>
                     <td>
                        <span class="glyphicon glyphicon-collapse-down" id="expand{ $unik }"
                              title="Expand the blank node"
                              onclick="$('#table{ $unik }').slideToggle();
                                       $('#expand{ $unik }').toggle(); $('#collapse{ $unik }').toggle();"/>
                        <span class="glyphicon glyphicon-collapse-up"   id="collapse{ $unik }"
                              title="Collapse the blank node" style="display: none"
                              onclick="$('#table{ $unik }').slideToggle();
                                       $('#collapse{ $unik }').toggle(); $('#expand{ $unik }').toggle();"/>
                        { ' ' }
                        { local:display-value($o, 'rsrc', $root, $decls) }
                     </td>
                     <td rowspan="2">{ local:display-type($o) }</td>
                  </tr>,
                  <tr>
                     <td id="table{ $unik }" style="display: none"> {
                        local:subject-table($o, $root, $rules, $decls, fn:false())
                     }
                     </td>
                  </tr>
               )
            else
               <tr>
                  <td>{ local:display-value($p, 'prop', $root, $decls) }</td>
                  <td>{ local:display-value($o, 'rsrc', $root, $decls) }</td>
                  <td>{ local:display-type($o) }</td>
               </tr>
      }
      </tbody>
   </table>
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
      <span class="glyphicon glyphicon-link" title="Resource"/>
   else if ( sem:isBlank($v) ) then
      <span class="glyphicon glyphicon-unchecked" title="Blank node"/>
   else if ( sem:isNumeric($v) ) then
      <span class="glyphicon glyphicon-usd"  title="Number"/>
   else if ( sem:lang($v) ) then
      sem:lang($v) ! <span class="glyphicon glyphicon-font" title="String, language: { . }">&#160;{ . }</span>
   else
      (: Assuming a string? :)
      <span class="glyphicon glyphicon-font" title="String"/>
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
            let $schemes := dbc:config-uri-schemes($db)
            let $decls   := dbc:config-triple-prefixes($db)
            return
               v:ensure-triple-index($db, function() {
                  t:query($db, function() {
                     local:page($db, $start, $rsrc, $curie, $init, $rules, $decls)
                  })
               })
         })
      })
