xquery version "3.0";

import module namespace b = "http://expath.org/ns/ml/console/browse" at "browse-lib.xql";
import module namespace a = "http://expath.org/ns/ml/console/admin"  at "../lib/admin.xql";
import module namespace t = "http://expath.org/ns/ml/console/tools"  at "../lib/tools.xql";
import module namespace v = "http://expath.org/ns/ml/console/view"   at "../lib/view.xql";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare namespace h   = "http://www.w3.org/1999/xhtml";
declare namespace cts = "http://marklogic.com/cts";

declare namespace xdmp = "http://marklogic.com/xdmp";

(:~
 : The overall page function.
 : 
 : TODO: Display whether the directory exists per se in MarkLogic (and its
 : properties if it has any, etc.)
 :
 : TODO: Is there a way to detect whether there is a URI Privilege for a specific
 : directory?  A way to say "the creation of documents in this directory is
 : protected by privilege xyz..."
 :
 : TODO: Document... (especially the fact it accesses the entire URI index,
 : should be a problem with large databases, with a shit loads of documents.
 :
 : TODO: The details of how to retrieve the children must be in lib/admin.xql.
 :
 : TODO: Lot of duplicated code with local:page() in roots.xq, factorize out?
 :)
declare function local:page(
   $db     as element(a:database),
   $uri    as xs:string?,
   $root   as xs:string,
   $sep    as xs:string,
   $iscoll as xs:boolean,
   $start  as xs:integer
) as element()+
{
   <p>
      { xs:string($db/a:name) ! v:db-link('../' || ., .) }
      { ' ' }
      { v:dir-link(t:when($iscoll, 'croots', 'roots'), '[roots]') }
      { ' ' }
      { b:uplinks($uri, $root, $sep, fn:true(), $iscoll) }
   </p>,
   t:unless($iscoll,
      b:create-doc-form('../../', $db/a:name, $uri, $root, $sep)),
   b:display-list(
      $uri,
      $root,
      $sep,
      if ( $iscoll ) then
         b:get-children-coll($uri, $sep, $start)
      else
         b:get-children-uri($uri, $sep, $start),
      t:when($iscoll, 'cdir', 'dir'),
      $start,
      function($child as xs:string, $pos as xs:integer) {
         if ( $iscoll ) then
            local:coll-item($child, $root, $sep)
         else
            local:dir-item($uri, $root, $child, $pos, $sep)
      },
      function($items as element(h:li)+) {
         if ( fn:exists($items) ) then (
            t:when($iscoll,
               <ul>{ $items }</ul>,
               local:children($uri, $root, $sep, $items))
         )
         else (
            <p>The directory is empty.</p>
         )
      })
};

(:~
 : Format one directory, in case of directory browsing (as opposed to collections).
 :)
declare function local:dir-item(
   $path  as xs:string,
   $root  as xs:string,
   $child as xs:string,
   $pos   as xs:integer,
   $sep   as xs:string
) as element()+
{
   let $kind := if ( fn:ends-with($child, $sep) ) then 'dir' else 'doc'
   return
      <li>
         <input name="name-{ $pos }" type="hidden" value="{ $child }"/>
         <input name="delete-{ $kind }-{ $pos }" type="checkbox"/>
         { ' ' }
         {
            if ( $kind eq 'dir' ) then
               v:dir-link('', $child, $root, $sep)
            else
               v:doc-link('', $child, $root, $sep)
         }
      </li>
};

(:~
 : Format one directory, in case of collection browsing.
 :)
declare function local:coll-item(
   $child as xs:string,
   $root  as xs:string,
   $sep   as xs:string
) as element()+
{
   if ( fn:ends-with($child, $sep) ) then (
      (: display as a "dir" :)
      <li>{ v:cdir-link('', $child, $root, $sep) }</li>,
      (: and maybe as a "final collection" too :)
      t:when(fn:exists(cts:collection-match($child)),
         <li>{ v:coll-link('', $child, $root, $sep) }</li>)
   )
   (: if not it is a "final collection" :)
   else (
      <li>{ v:coll-link('', $child, $root, $sep) } </li>
   )
};

(:~
 : @todo Duplicated in roots.xq.  To factorize out...
 :)
declare function local:children(
   $path  as xs:string,
   $root  as xs:string,
   $sep   as xs:string,
   $items as element(h:li)+
) as element()+
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
      (: TODO: Adapt this to the new dir/doc browsing (no browse/{path} anymore), :)
      v:input-hidden('back-url', 'dir?uri=' || fn:encode-for-uri($path) || '&amp;root='
         || fn:encode-for-uri($root) || '&amp;sep=' || fn:encode-for-uri($sep)))
};

(:~
 : @todo Duplicated in roots.xq.  Have a t:* function for enumerations?
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
let $root    := t:mandatory-field('root')
let $sep     := t:mandatory-field('sep')
let $type    := t:mandatory-field('type')
let $iscoll  := local:param-iscoll($type)
let $prefix  := t:optional-field('prefix', ())[.]
(: TODO: Do we actually want to ensure $uri ends with the separator? :)
(: And similarly that there is a separator between $prefix and the given URI? :)
(:
let $uri__   := t:mandatory-field('uri')[.]
let $uri_    := if ( $uri__ and fn:ends-with($uri__, $sep) ) then $uri__ else $uri__ || $sep
let $uri     := if ( fn:exists($prefix) ) then
                  if ( fn:ends-with($prefix, $sep) and fn:starts-with($uri_, $sep) ) then
                     $prefix || fn:substring($uri_, 2)
                  else if ( fn:ends-with($prefix, $sep) or fn:starts-with($uri_, $sep) ) then
                     $prefix || $uri_
                  else
                     $prefix || $sep || $uri_
               else
                  $uri_
:)
let $uri_    := t:mandatory-field('uri')[.]
let $uri     := if ( fn:exists($prefix) ) then $prefix || $uri_ else $uri_
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
                     local:page($db, $uri, $root, $sep, $iscoll, $start)
                  })
               })
         })
      },
      b:create-doc-javascript())
