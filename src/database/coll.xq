xquery version "3.0";

import module namespace b   = "http://expath.org/ns/ml/console/browse"          at "browse-lib.xqy";
import module namespace dbc = "http://expath.org/ns/ml/console/database/config" at "db-config-lib.xqy";

import module namespace a = "http://expath.org/ns/ml/console/admin" at "../lib/admin.xqy";
import module namespace t = "http://expath.org/ns/ml/console/tools" at "../lib/tools.xqy";
import module namespace v = "http://expath.org/ns/ml/console/view"  at "../lib/view.xqy";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare namespace c = "http://expath.org/ns/ml/console";
declare namespace h = "http://www.w3.org/1999/xhtml";

(:~
 : The overall page function.
 :
 : TODO: The details of how to retrieve the children must be in lib/admin.xqy.
 :)
declare function local:page(
   $db     as element(a:database),
   $uri    as xs:string?,
   $start  as xs:integer,
   $schemes as element(c:scheme)+
) as element()+
{
   let $resolved := b:resolve-path($uri, fn:true(), $schemes)
   let $root     := xs:string($resolved/@root)
   let $sep      := xs:string($resolved/@sep)
   return (
      <p>
         { xs:string($db/a:name) ! v:db-link('../' || ., .) }
         { ' ' }
         { v:component-link('croots', '[roots]', 'dir') }
         { ' ' }
         {
            if ( fn:exists($sep[.]) ) then (
               b:uplinks($uri, $root, $sep, fn:false(), fn:true()),
               ' ',
               v:coll-link('', $uri, $sep)
            )
            else (
               v:coll-link('', $uri)
            )
         }
      </p>,
      b:display-list(
         $uri,
         ( fn:collection($uri) ! fn:document-uri(.) )
            [fn:position() ge $start and fn:position() lt $start + $b:page-size],
         'coll',
         $start,
         function($child as xs:string, $pos as xs:integer) {
            <li> {
               v:doc-link('', $child)
            }
            </li>
         },
         function($items as element(h:li)+) {
            t:when(fn:exists($items),
               <ul>{ $items }</ul>,
               <p>The collection is empty.</p>)
         })
   )
};

let $name  := t:mandatory-field('name')
let $uri   := t:mandatory-field('uri')
let $start := xs:integer(t:optional-field('start', 1)[.])
return
   v:console-page(
      '../../',
      'db',
      'Browse collections',
      function() {
         v:ensure-db($name, function($db) {
            let $schemes := dbc:config-uri-schemes($db)
            return
               t:query($db, function() {
                  local:page($db, $uri, $start, $schemes)
               })
         })
      },
      <lib>emlc.browser</lib>)
