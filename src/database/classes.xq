xquery version "3.0";

import module namespace a   = "http://expath.org/ns/ml/console/admin" at "../lib/admin.xql";
import module namespace t   = "http://expath.org/ns/ml/console/tools" at "../lib/tools.xql";
import module namespace v   = "http://expath.org/ns/ml/console/view"  at "../lib/view.xql";
import module namespace sem = "http://marklogic.com/semantics" at "/MarkLogic/semantics.xqy";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare namespace c   = "http://expath.org/ns/ml/console";
declare namespace h   = "http://www.w3.org/1999/xhtml";
declare namespace map = "http://marklogic.com/xdmp/map";

(: Fixed page size for now. :)
declare variable $page-size := 100;

(:~
 : The overall page function.
 :)
declare function local:page(
   $name  as xs:string,
   $start as xs:integer,
   $super as xs:string?,
   $curie as xs:string?,
   $decls as element(c:decl)*
) as element()+
{
   let $db := a:get-database($name)
   return
      (: TODO: In this case, we should NOT return "200 OK". :)
      if ( fn:empty($db) ) then (
         local:page--no-db($name)
      )
      else if ( $super[.] ) then (
         local:page--super($db, $super, $start, './')
      )
      else if ( $curie[.] ) then (
         local:page--super($db, v:expand-curie($curie, $decls), $start, '../')
      )
      else (
         local:page--browse($db, $start)
      )
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
declare function local:page--browse($db as element(a:database), $start as xs:integer)
   as element()+
{
   <p>Database: { v:db-link('classes', $db/a:name) }</p>,
   <p> {
      (: TODO: As it is, the query includes blank nodes. Filter them out! :)
      (: TODO: Pass parameters properly, instead of concatenating values. :)
      (: TODO: What if several rdfs:label?  Backport labels to resource browsing? :)
      let $query :=
            'PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
             SELECT ?root ?label WHERE {
                ?root a rdfs:Class .
                OPTIONAL { ?root rdfs:label ?label . }
                OPTIONAL {
                   ?root rdfs:subClassOf ?super .
                   ?super a rdfs:Class .
                   filter ( ?root != ?super )
                }
                # "optional" and "filter" to simulate "filter not exists"
                FILTER ( ! ?super )
                # filter out blank nodes (yes, they can be classes as well)
                FILTER ( isIRI(?root) )
             }
             ORDER BY ?root
             OFFSET ' || $start - 1 || '
             LIMIT ' || $page-size
      let $res   :=
            sem:sparql(
               $query,
               (),
               (),
               sem:ruleset-store('rdfs.rules', sem:store()))
      let $count := fn:count($res)
      let $to    := $start + $count - 1
      return (
         'Results ' || $start || ' to ' || $to,
         t:when($start gt 1,
            (', ', <a href="classes?start={ $start - $page-size }">previous page</a>)),
         t:when($count eq $page-size,
            (', ', <a href="classes?start={ $start + $count }">next page</a>)),
         ':',
         for $r     in $res
         let $root  := map:get($r, 'root')
         let $label := map:get($r, 'label')
         return
            <li>
               { v:class-link('classes', $root) }
               { text { ' - ' || $label } }
            </li>
      )
   }
   </p>
};

(:~
 : The page content, when browsing resource list.
 :
 : TODO: DISPLAY THE CLASS RESOURCE INSTANCES INSTEAD !!!
 :)
declare function local:page--super(
   $db    as element(a:database),
   $super as xs:string,
   $start as xs:integer,
   $root  as xs:string
) as element()+
{
   let $params := map:entry('super', sem:iri($super))
   let $store  := sem:ruleset-store('rdfs.rules', sem:store())
   return (
      <p>Database: { v:db-link($root || 'classes', $db/a:name) }</p>,
      <p>Details of { v:class-link($root || 'classes', $super) }:</p>,
      <table class="table table-striped">
         <thead>
            <th>Sub-class of</th>
            <th>Label</th>
         </thead>
         <tbody> {
            (: TODO: WINDOWING: FIXME: For now, we truncate the result set, but there
               is no navigation links between pages (next, prev, etc.) nor even
               indicators (classes 1 to 100, etc.) :)
            let $query :=
                  'PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
                   SELECT ?class ?label WHERE {
                      ?super rdfs:subClassOf ?class .
                      OPTIONAL { ?class rdfs:label ?label . }
                      # filter out blank nodes (yes, they can be classes as well)
                      FILTER ( isIRI(?class) )
                   }
                   ORDER BY ?class
                   OFFSET ' || $start - 1 || '
                   LIMIT ' || $page-size
            let $res   := sem:sparql($query, $params, (), $store)
            for $r     in $res
            return
               (: TODO: Abbreviate properties, based on configured prefixes (or well-known?) :)
               <tr>
                  <td>{ local:display-value(map:get($r, 'class'), $root) }</td>
                  <td>{ local:display-value(map:get($r, 'label'), $root) }</td>
               </tr>
         }
         </tbody>
      </table>,
      <table class="table table-striped">
         <thead>
            <th>Sub-class</th>
            <th>Label</th>
         </thead>
         <tbody> {
            (: TODO: WINDOWING: FIXME: For now, we truncate the result set, but there
               is no navigation links between pages (next, prev, etc.) nor even
               indicators (classes 1 to 100, etc.) :)
            let $query :=
                  'PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
                   SELECT ?class ?label WHERE {
                      ?class rdfs:subClassOf ?super .
                      OPTIONAL { ?class rdfs:label ?label . }
                      # filter out blank nodes (yes, they can be classes as well)
                      FILTER ( isIRI(?class) )
                   }
                   ORDER BY ?class
                   OFFSET ' || $start - 1 || '
                   LIMIT ' || $page-size
            let $res   := sem:sparql($query, $params, (), $store)
            for $r     in $res
            return
               (: TODO: Abbreviate properties, based on configured prefixes (or well-known?) :)
               <tr>
                  <td>{ local:display-value(map:get($r, 'class'), $root) }</td>
                  <td>{ local:display-value(map:get($r, 'label'), $root) }</td>
               </tr>
         }
         </tbody>
      </table>
   )
};

declare function local:display-value($v as xs:anyAtomicType?, $root as xs:string)
   as element()?
{
   if ( fn:empty($v) ) then
      ()
   else if ( sem:isIRI($v) ) then
      (: TODO: Display the link only when the resource exists (that is, there is
         at least one triple with that IRI as subkect). :)
      v:class-link($root || 'classes', $v)
   else
      <span>{ $v }</span>
};

let $db    := t:mandatory-field('name')
let $super := t:optional-field('super', ())
let $curie := t:optional-field('curie', ())
let $start := xs:integer(t:optional-field('start', 1)[.])
let $root  := '../../' || '../'[$curie]
let $decls := t:config-triple-prefixes($db)
return
   v:console-page($root, 'browser', 'Browse classes', function() {
      t:query($db, function() {
         local:page($db, $start, $super, $curie, $decls)
      })
   })
