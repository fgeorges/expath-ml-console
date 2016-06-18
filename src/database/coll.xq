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
   let $to    := $start + $b:page-size - 1
   let $docs  :=
         ( fn:collection($uri) ! fn:document-uri(.) )
         [fn:position() ge $start and fn:position() le $to]
   let $count := fn:count($docs)
   return
      if ( fn:exists($docs) ) then (
         <p>
            Content of <code>{ $uri }</code>, results { $start } to { $start + $count - 1 }{
               t:when($start gt 1,
                  (', ', <a href="coll?start={ $start - $b:page-size }&amp;uri={ $uri }&amp;root={ $root }&amp;sep={ $sep }">previous page</a>)),
               t:when($count eq $b:page-size,
                  (', ', <a href="coll?start={ $to + 1 }&amp;uri={ $uri }&amp;root={ $root }&amp;sep={ $sep }">next page</a>))
            }:
         </p>,
         <ul> {
            for $d in $docs
            return
               <li> {
                  v:doc-full-link('', $d, $root, $sep)
               }
               </li>
         }
         </ul>
      )
      else (
         <p>No document in the collection.</p>
      )
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
               a:query-database($db, function() {
                  local:page($db, $uri, $root, $sep, $start)
               })
         })
      },
      b:create-doc-javascript())
