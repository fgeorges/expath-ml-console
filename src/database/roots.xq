xquery version "3.0";

import module namespace b   = "http://expath.org/ns/ml/console/browse" at "browse-lib.xql";
import module namespace a   = "http://expath.org/ns/ml/console/admin"  at "../lib/admin.xql";
import module namespace bin = "http://expath.org/ns/ml/console/binary" at "../lib/binary.xql";
import module namespace t   = "http://expath.org/ns/ml/console/tools"  at "../lib/tools.xql";
import module namespace v   = "http://expath.org/ns/ml/console/view"   at "../lib/view.xql";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare namespace h    = "http://www.w3.org/1999/xhtml";
declare namespace cts  = "http://marklogic.com/cts";
declare namespace xdmp = "http://marklogic.com/xdmp";
declare namespace map  = "http://marklogic.com/xdmp/map";
declare namespace sec  = "http://marklogic.com/xdmp/security";

(:~
 : The page content.
 : 
 : TODO: Displays only "/" and "http://*/" for now.  Find anything else that
 : ends with a "/" as well.  Maybe even "urn:*:" URIs?
 :
 : TODO: Lot of duplicated code with local:page() in dir.xq, factorize out?
 :)
declare function local:page($db as element(a:database), $iscoll as xs:boolean, $start as xs:integer)
   as element()+
{
   <p>
      { xs:string($db/a:name) ! v:db-link('../' || ., .) }
      { ' ' }
      { v:dir-link(t:when($iscoll, 'croots', 'roots'), '[roots]') }
   </p>,
   t:unless($iscoll,
      b:create-doc-form('../../', $db/a:name, (), (), ())),
   b:display-list(
      (),
      (),
      (),
      (: TODO: Externalize "/", "http://", "." and "urn:" :)
      ( <path sep="/">/</path>[fn:exists(local:uris($iscoll, '/', '/'))],
        local:uris($iscoll, 'http://', '/'),
        local:uris($iscoll, '.', '/'),
        local:uris($iscoll, 'urn:', ':') )
         [fn:position() ge $start and fn:position() lt $start + $b:page-size],
      t:when($iscoll, 'croots', 'roots'),
      $start,
      function($child as element(path), $pos as xs:integer) {
         if ( $iscoll ) then
            local:coll-item($child, $child/@sep)
         else
            local:dir-item($child, $child/@sep, $pos)
      },
      function($items as element(h:li)*) {
         if ( fn:exists($items) ) then (
            <p>Choose the root to navigate:</p>,
            t:when($iscoll,
               <ul>{ $items }</ul>,
               local:children($items))
         )
         else (
            <p>The database is empty.</p>
         )
      })
};

(:~
 : Format one root, in case of directory browsing (as opposed to collections).
 :)
declare function local:dir-item(
   $child as xs:string,
   $sep   as xs:string,
   $pos   as xs:integer
) as element()+
{
   <li>
      <input name="name-{ $pos }"       type="hidden" value="{ $child }"/>
      <input name="delete-dir-{ $pos }" type="checkbox"/>
      { ' ' }
      { v:root-link('', $child, $sep) }
   </li>
};

(:~
 : Format one root, in case of collection browsing.
 :)
declare function local:coll-item(
   $child as xs:string,
   $sep   as xs:string
) as element()+
{
   if ( fn:ends-with($child, $sep) ) then (
      (: display as a "dir" :)
      <li>{ v:croot-link('', $child, $sep) }</li>,
      (: and maybe as a "final collection" too :)
      t:when(fn:exists(cts:collection-match($child)),
         <li>{ v:coll-link('', $child, $child, $sep) }</li>)
   )
   (: if not it is a "final collection" :)
   else (
      <li>{ v:coll-link('', $child, $child, $sep) } </li>
   )
};

(:~
 : ...
 :)
declare function local:uris(
   $iscoll as xs:boolean,
   $base   as xs:string,
   $sep    as xs:string
) as element(path)*
{
   if ( $iscoll ) then
      b:get-children-coll($base, $sep, ())
   else
      b:get-children-uri($base, $sep, ())
};

(:~
 : @todo Duplicated in dir.xq.  To factorize out...
 :)
declare function local:children($items as element(h:li)+) as element()+
{
   v:form(
      '',
      attribute { 'id' } { 'orig-form' },
      <ul style="list-style-type: none"> {
         $items
      }
      </ul>),
   <button class="btn btn-danger"
           title="Delete selected documents and directories"
           onclick='deleteUris("orig-form", "hidden-form");'>
      Delete
   </button>,
   v:inline-form(
      'bulk-delete',
      (attribute { 'id'    } { 'hidden-form' },
       attribute { 'style' } { 'display: none' }),
      v:input-hidden('back-url', 'roots'))
};

(:~
 : @todo Duplicated in dir.xq.  Have a t:* function for enumerations?
 :)
declare function local:param-iscoll($type as xs:string) as xs:boolean
{
   if ( $type eq 'docs' ) then
      fn:false()
   else if ( $type eq 'coll' ) then
      fn:true()
   else
      t:error('unkown-enum', 'Unknown root type: ' || $type)
};

let $name    := t:mandatory-field('name')
let $type    := t:mandatory-field('type')
let $iscoll  := local:param-iscoll($type)
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
         v:ensure-db($name, function() {
            let $db := a:get-database($name)
            return
               $lexicon($db, function() {
                  a:query-database($db, function() {
                     local:page($db, $iscoll, $start)
                  })
               })
         })
      },
      b:create-doc-javascript())
