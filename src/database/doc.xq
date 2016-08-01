xquery version "3.0";

import module namespace b   = "http://expath.org/ns/ml/console/browse" at "browse-lib.xql";
import module namespace a   = "http://expath.org/ns/ml/console/admin"  at "../lib/admin.xql";
import module namespace bin = "http://expath.org/ns/ml/console/binary" at "../lib/binary.xql";
import module namespace t   = "http://expath.org/ns/ml/console/tools"  at "../lib/tools.xql";
import module namespace v   = "http://expath.org/ns/ml/console/view"   at "../lib/view.xql";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare namespace c    = "http://expath.org/ns/ml/console";
declare namespace xdmp = "http://marklogic.com/xdmp";
declare namespace sec  = "http://marklogic.com/xdmp/security";

(:~
 : The overall page function.
 :)
declare function local:page($db as element(a:database), $uri as xs:string, $schemes as element(c:scheme)+)
   as element()+
{
   let $resolved := b:resolve-path($uri, fn:false(), $schemes)
   let $root     := xs:string($resolved/@root)
   let $sep      := xs:string($resolved/@sep)
   let $db-name  := xs:string($db/a:name)
   let $db-root  := './'
   let $webapp   := '../../'
   let $dir      := if ( fn:contains($uri, $sep) ) then
                       fn:string-join(fn:tokenize($uri, $sep)[fn:position() lt fn:last()], $sep) || $sep
                    else
                       $root
   return (
      <p>
         { $db-name ! v:db-link('../' || ., .) }
         { ' ' }
         { v:dir-link('roots', '[roots]') }
         { ' ' }
         { b:uplinks($uri, $root, $sep, fn:false(), fn:false()) }
         { ' ' }
         { v:doc-link('', $uri, $root, $sep) }
      </p>,
      if ( fn:not(fn:doc-available($uri)) ) then (
         <p>The document <code>{ $uri }</code> does not exist.</p>
      )
      else (
         local:summary($uri),
         local:content($uri, $dir, $root, $sep, $db-root),
         local:collections($db, $uri, $db-root, $webapp, $root, $sep),
         local:properties($uri),
         local:permissions($db, $uri, $webapp)
      )
   )
};

(:~
 : The summary section.
 :)
declare function local:summary($uri as xs:string)
   as element()+
{
   <h3>Summary</h3>,
   <table class="table table-bordered datatable">
      <thead>
         <th>Name</th>
         <th>Value</th>
      </thead>
      <tbody>
         <tr>
            <td>Type</td>
            <td> {
               typeswitch ( fn:doc($uri)/node() )
                  case element() return 'XML'
                  case text()    return 'Text'
                  default        return 'Binary'
            }
            </td>
         </tr>
         <tr>
            <td>Document URI</td>
            <td><code>{ $uri }</code></td>
         </tr>
         <tr>
            <td>Forest</td>
            <td>{ xdmp:forest-name(xdmp:document-forest($uri)) }</td>
         </tr>
         <tr>
            <td>Quality</td>
            <td>{ xdmp:document-get-quality($uri) }</td>
         </tr>
      </tbody>
   </table>
};

(:~
 : The content section.
 :)
declare function local:content($uri as xs:string, $dir as xs:string, $root as xs:string, $sep as xs:string, $db-root as xs:string)
   as element()+
{
   <h3>Content</h3>,
   let $doc := fn:doc($uri)
   let $id  := fn:generate-id($doc)
   return

(:
   TODO: If temporal, only display, if not then "edit" (buttons save + delete).
   In fact, generalize the idea of the editor panel.
   Have a plain one (to display), then allow some extension (that is, more
   buttons, and some other config options to allow editing)...

   let $tmp := a:is-temporal($uri)
:)

      if ( bin:is-json($doc/node()) ) then (
         v:edit-json($doc, $id, $uri, $dir, $root, $sep, $db-root)
      )
      else if ( fn:exists($doc/*) ) then (
         v:edit-xml($doc, $id, $uri, $dir, $root, $sep, $db-root)
      )
      else if ( fn:exists($doc/text()) and fn:empty($doc/node()[2]) ) then (
         (: TODO: Use the internal MarkLogic way to recognize XQuery modules? :)
         let $mode := ( 'xquery'[fn:matches($uri, '\.xq[ylm]?$')],
                        'javascript'[fn:ends-with($uri, '.sjs')],
                        'json'[fn:ends-with($uri, '.json')],
                        'text' )[1]
         return
            v:edit-text($doc/text(), $mode, $id, $uri, $dir, $root, $sep, $db-root)
      )
      else (
         <p>Binary document display not supported.</p>
         (:
         TODO: Implement binary doc deletion, without the ACE editor to hold the
         document URI...  Actually, should be easy to change using the ID, and
         use the URI instead...
         <button class="btn btn-danger" onclick='deleteDoc("{ $id }");'>
            Delete
         </button>
         :)
      )
};

(:~
 : The collections section.
 :)
declare function local:collections(
   $db      as element(a:database),
   $uri     as xs:string,
   $db-root as xs:string,
   $webapp  as xs:string,
   $root    as xs:string,
   $sep     as xs:string
) as element()+
{
   <h3>Collections</h3>,
   let $colls := xdmp:document-get-collections($uri)
   return
      if ( fn:empty($colls) ) then
         <p>This document is not part of any collection.</p>
      else
         <table class="table table-bordered">
            <thead>
               <th>Collection</th>
               <th>Remove</th>
            </thead>
            <tbody> {
               for $c in $colls
               order by $c
               return
                  <tr>
                     <td>{ v:coll-link($db-root || 'coll?uri=' || fn:encode-for-uri($c), $c) }</td>
                     <td> {
                        v:inline-form($root || 'tools/del-coll', (
                           v:input-hidden('collection', $c),
                           v:input-hidden('uri', $uri),
                           v:input-hidden('database', $db/@id),
                           v:input-hidden('redirect', 'true'),
                           (: TODO: Replace with a Bootstrap character icon... :)
                           v:submit('Remove')))
                     }
                     </td>
                  </tr>
            }
            </tbody>
         </table>,
   v:form($root || 'tools/add-coll', (
      v:input-text('collection', 'Add collection', 'The collection URI to add the document to'),
      v:input-hidden('uri', $uri),
      v:input-hidden('database', $db/@id),
      v:input-hidden('redirect', 'true'),
      (: TODO: Replace with a Bootstrap character icon... :)
      v:submit('Add')))
};

(:~
 : The properties section.
 :)
declare function local:properties($uri as xs:string) as element()+
{
   <h3>Properties</h3>,
   let $props := xdmp:document-properties($uri)
   return
      if ( fn:exists($props) ) then
         v:display-xml($props/*)
      else
         <p>This document does not have any property.</p>
};

(:~
 : The permissions section.
 :)
declare function local:permissions(
   $db   as element(a:database),
   $uri  as xs:string,
   $root as xs:string
) as element()+
{
   <h3>Permissions</h3>,
   let $perms := xdmp:document-get-permissions($uri)
   return
      if ( fn:empty($perms) ) then
         <p>This document does not have any permission.</p>
      else
         <table class="table table-bordered">
            <thead>
               <th>Capability</th>
               <th>Role</th>
               <th>Remove</th>
            </thead>
            <tbody> {
               for $perm       in $perms
               let $capability := xs:string($perm/sec:capability)
               let $role       := a:role-name($perm/sec:role-id)
               return
                  <tr>
                     <td>{ $capability }</td>
                     <td>{ $role }</td>
                     <td> {
                        v:inline-form($root || 'tools/del-perm', (
                           <input type="hidden" name="capability" value="{ $capability }"/>,
                           <input type="hidden" name="role"       value="{ $role }"/>,
                           <input type="hidden" name="uri"        value="{ $uri }"/>,
                           <input type="hidden" name="database"   value="{ $db/@id }"/>,
                           <input type="hidden" name="redirect"   value="true"/>,
                           (: TODO: Replace with a Bootstrap character icon... :)
                           v:submit('Remove')))
                     }
                     </td>
                  </tr>
            }
            </tbody>
         </table>,
   <p>Add a permission:</p>,
   <form class="form-inline" action="{ $root }tools/add-perm" method="post">
      <div class="form-group">
         <label for="capability">Capability&#160;&#160;</label>
         <select name="capability" class="form-control">
            <option value="read">Read</option>
            <option value="update">Update</option>
            <option value="insert">Insert</option>
            <option value="execute">Execute</option>
         </select>
      </div>
      <div class="form-group">
         <label for="role">&#160;&#160;&#160;&#160;Role&#160;&#160;</label>
         <select name="role" class="form-control"> {
            for $role in a:get-roles()/a:role/a:name
            order by $role
            return
               <option value="{ $role }">{ $role }</option>
         }
         </select>
      </div>
      <input type="hidden" name="uri"      value="{ $uri }"/>
      <input type="hidden" name="database" value="{ $db/@id }"/>
      <input type="hidden" name="redirect" value="true"/>
      <button type="submit" class="btn btn-default">Add</button>
   </form>
};

let $name := t:mandatory-field('name')
let $uri  := t:mandatory-field('uri')
return
   v:console-page(
      '../../',
      'db',
      'Browse documents',
      function() {
         v:ensure-db($name, function() {
            let $db      := a:get-database($name)
            let $schemes := t:config-uri-schemes($db)
            return
               t:query($db, function() {
                  local:page($db, $uri, $schemes)
               })
         })
      },
      b:create-doc-javascript())
