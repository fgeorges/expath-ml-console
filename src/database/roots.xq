xquery version "3.0";

import module namespace b   = "http://expath.org/ns/ml/console/browse"          at "browse-lib.xql";
import module namespace dbc = "http://expath.org/ns/ml/console/database/config" at "db-config-lib.xql";

import module namespace a   = "http://expath.org/ns/ml/console/admin"  at "../lib/admin.xqy";
import module namespace bin = "http://expath.org/ns/ml/console/binary" at "../lib/binary.xql";
import module namespace t   = "http://expath.org/ns/ml/console/tools"  at "../lib/tools.xql";
import module namespace v   = "http://expath.org/ns/ml/console/view"   at "../lib/view.xql";

declare namespace c   = "http://expath.org/ns/ml/console";
declare namespace h   = "http://www.w3.org/1999/xhtml";
declare namespace cts = "http://marklogic.com/cts";

(:~
 : The page content.
 : 
 : TODO: Lot of duplicated code with local:page() in dir.xq, factorize out?
 :)
declare function local:page(
   $db      as element(a:database),
   $iscoll  as xs:boolean,
   $start   as xs:integer,
   $schemes as element(c:scheme)+
) as element()+
{
   <p xmlns="http://www.w3.org/1999/xhtml">
      { xs:string($db/a:name) ! v:db-link('../' || ., .) }
      { ' ' }
      { v:component-link(t:when($iscoll, 'croots', 'roots'), '[roots]', 'dir') }
   </p>,
   t:unless($iscoll,
      b:create-doc-form('../../', $db/a:name, ())),
   b:display-list(
      (),
      b:get-roots($iscoll, $start, $schemes),
      t:when($iscoll, 'croots', 'roots'),
      $start,
      t:when($iscoll, local:coll-item#2, local:dir-item#2),
      function($items as element(h:li)*) {
         if ( fn:exists($items) ) then (
            <p xmlns="http://www.w3.org/1999/xhtml">Choose the root to navigate:</p>,
            t:when($iscoll,
               <ul xmlns="http://www.w3.org/1999/xhtml">{ $items }</ul>,
               b:dir-children($items, 'roots'))
         )
         else (
            <p xmlns="http://www.w3.org/1999/xhtml">The database is empty.</p>
         )
      })
};

(:~
 : Format one root, in case of directory browsing (as opposed to collections).
 :)
declare function local:dir-item(
   $child as element(path),
   $pos   as xs:integer
) as element()+
{
   <li xmlns="http://www.w3.org/1999/xhtml">
      <input name="name-{ $pos }"       type="hidden" value="{ $child }"/>
      <input name="delete-dir-{ $pos }" type="checkbox"/>
      { ' ' }
      { v:root-link('', $child) }
   </li>
};

(:~
 : Format one root, in case of collection browsing.
 :)
declare function local:coll-item(
   $child as element(path),
   $pos   as xs:integer
) as element()+
{
   let $sep := xs:string($child/@sep)[.]
   return
      if ( fn:ends-with($child, $sep) ) then (
         (: display as a "dir" :)
         t:when(fn:exists($sep),
            <li xmlns="http://www.w3.org/1999/xhtml">{ v:croot-link('', $child) }</li>),
         (: and maybe as a "final collection" too :)
         t:when(fn:exists(cts:collection-match($child)),
            <li xmlns="http://www.w3.org/1999/xhtml">{ v:coll-link('', $child) }</li>)
      )
      (: if not it is a "final collection" :)
      else (
         <li xmlns="http://www.w3.org/1999/xhtml">{ v:coll-link('', $child) } </li>
      )
};

let $name    := t:mandatory-field('name')
let $type    := t:mandatory-field('type')
let $iscoll  := b:param-iscoll($type)
let $start   := xs:integer(t:optional-field('start', 1)[.])
let $lexicon := t:when($iscoll, v:ensure-coll-lexicon#2, v:ensure-uri-lexicon#2)
return
   v:console-page(
      '../../',
      'db',
      t:when($iscoll,
         'Browse collections',
         'Browse documents'),
      function() {
         v:ensure-db($name, function($db) {
            let $schemes := dbc:config-uri-schemes($db)
            return
               $lexicon($db, function() {
                  t:query($db, function() {
                     local:page($db, $iscoll, $start, $schemes)
                  })
               })
         })
      },
      b:create-doc-javascript())
