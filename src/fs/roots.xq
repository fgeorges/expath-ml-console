xquery version "3.0";

import module namespace b = "http://expath.org/ns/ml/console/browse" at "../database/browse-lib.xql";

import module namespace a = "http://expath.org/ns/ml/console/admin" at "../lib/admin.xqy";
import module namespace t = "http://expath.org/ns/ml/console/tools" at "../lib/tools.xql";
import module namespace v = "http://expath.org/ns/ml/console/view"  at "../lib/view.xql";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare namespace dir = "http://marklogic.com/xdmp/directory";
declare namespace h   = "http://www.w3.org/1999/xhtml";

declare function local:page() as element()+
{
   <p>
      { v:component-link('roots', '[roots]', 'dir') }
   </p>,
   (:TODO: Create form not supported yet on FS... :)
   (: b:create-doc-form('../../', $db/a:name, $uri), :)
   b:display-list(
      (),
      local:get-children(),
      'dir',
      1,
      function($child as xs:string, $pos as xs:integer) {
         local:item($child)
      },
      function($items as element(h:li)+) {
         if ( fn:exists($items) ) then (
            <ul>{ $items }</ul>
            (: TODO: Does not support delete form for FS yet... :)
            (: b:dir-children($items, $back-url) :)
         )
         else (
            <p>There is not root at all...</p>
         )
      })
};

(:~
 : Format one item.
 :)
declare function local:get-children() as xs:string*
{
   ('/', 'c:/')[a:get-directory(.)]
};

(:~
 : Format one item.
 :)
declare function local:item($child as item()) as element()+
{
   <li> {
      v:dir-link('', $child, '/')
   }
   </li>
};

v:console-page(
   '../../',
   'project',
   'Browse file system',
   local:page#0)
