xquery version "3.0";

import module namespace b = "http://expath.org/ns/ml/console/browse" at "browse-lib.xql";
import module namespace a = "http://expath.org/ns/ml/console/admin"  at "../lib/admin.xql";
import module namespace t = "http://expath.org/ns/ml/console/tools"  at "../lib/tools.xql";
import module namespace v = "http://expath.org/ns/ml/console/view"   at "../lib/view.xql";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare namespace h   = "http://www.w3.org/1999/xhtml";
declare namespace cts = "http://marklogic.com/cts";

(:~
 : The overall page function.
 :
 : TODO: The details of how to retrieve the children must be in lib/admin.xql.
 :)
declare function local:page(
   $db     as element(a:database),
   $uri    as xs:string?,
   $root   as xs:string,
   $sep    as xs:string,
   $start  as xs:integer
) as element()+
{
   <p>
      { xs:string($db/a:name) ! v:db-link('../' || ., .) }
      { ' ' }
      { v:dir-link('croots', '[roots]') }
      { ' ' }
      { b:uplinks($uri, $root, $sep, fn:false(), fn:true()) }
   </p>,
   b:display-list(
      $uri,
      $root,
      $sep,
      ( fn:collection($uri) ! fn:document-uri(.) )
         [fn:position() ge $start and fn:position() lt $start + $b:page-size],
      'coll',
      $start,
      function($child as xs:string, $pos as xs:integer) {
         <li> {
            v:doc-full-link('', $child, $root, $sep)
         }
         </li>
      },
      function($items as element(h:li)+) {
         t:when(fn:exists($items),
            <ul>{ $items }</ul>,
            <p>The collection is empty.</p>)
      })
};

let $name  := t:mandatory-field('name')
let $root  := t:mandatory-field('root')
let $sep   := t:mandatory-field('sep')
let $uri   := t:mandatory-field('uri')
let $start := xs:integer(t:optional-field('start', 1)[.])
return
   v:console-page(
      '../../',
      'db',
      'Browse collections',
      function() {
         v:ensure-db($name, function() {
            let $db := a:get-database($name)
            return
               t:query($db, function() {
                  local:page($db, $uri, $root, $sep, $start)
               })
         })
      },
      b:create-doc-javascript())
