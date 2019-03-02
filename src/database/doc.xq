xquery version "3.0";

import module namespace b   = "http://expath.org/ns/ml/console/browse"          at "browse-lib.xqy";
import module namespace dbc = "http://expath.org/ns/ml/console/database/config" at "db-config-lib.xqy";

import module namespace a       = "http://expath.org/ns/ml/console/admin"    at "../lib/admin.xqy";
import module namespace bin     = "http://expath.org/ns/ml/console/binary"   at "../lib/binary.xqy";
import module namespace t       = "http://expath.org/ns/ml/console/tools"    at "../lib/tools.xqy";
import module namespace triples = "http://expath.org/ns/ml/console/triples"  at "../lib/triples.xqy";
import module namespace v       = "http://expath.org/ns/ml/console/view"     at "../lib/view.xqy";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare namespace c    = "http://expath.org/ns/ml/console";
declare namespace h    = "http://www.w3.org/1999/xhtml";
declare namespace cts  = "http://marklogic.com/cts";
declare namespace sem  = "http://marklogic.com/semantics";
declare namespace xdmp = "http://marklogic.com/xdmp";
declare namespace map  = "http://marklogic.com/xdmp/map";
declare namespace sec  = "http://marklogic.com/xdmp/security";

(:~
 : The overall page function.
 :)
declare function local:page(
   $db      as element(a:database),
   $uri     as xs:string,
   $schemes as element(c:scheme)+,
   $decls   as element(c:decl)*
) as element()+
{
   let $resolved := b:resolve-path($uri, fn:false(), $schemes)
   let $root     := xs:string($resolved/@root)
   let $sep      := xs:string($resolved/@sep)
   let $db-name  := xs:string($db/a:name)
   let $dir      := if ( fn:exists($sep) and fn:contains($uri, $sep) ) then
                       fn:string-join(fn:tokenize($uri, $sep)[fn:position() lt fn:last()], $sep) || $sep
                    else
                       $root
   return (
      <p>
         { $db-name ! v:db-link('../' || ., .) }
         { ' ' }
         { v:component-link('roots', '[roots]', 'dir') }
         { ' ' }
         {
            if ( fn:exists($root) ) then (
               b:uplinks($uri, $root, $sep, fn:false(), fn:false()),
               ' ',
               v:doc-link('', $uri, $sep)
            )
            else (
               v:doc-link('', $uri)
            )
         }
      </p>,
      if ( fn:not(fn:doc-available($uri)) ) then (
         <p>The document <code>{ $uri }</code> does not exist.</p>
      )
      else (
         local:summary($uri),
         local:content($uri, $dir, $root, $sep),
         local:collections($db, $uri, $sep),
         local:metadata($db, $uri),
         local:properties($uri),
         local:permissions($db, $uri),
         if ( $db/a:triple-index/fn:boolean(.) ) then
            local:triples($uri, $decls)
         else
            ()
      )
   )
};

(:~
 : The summary section.
 :)
declare function local:remove-button()
   as element(h:button)
{
   <button type="submit" class="btn btn-outline-danger btn-sm" style="margin-top: -5px">
      <span class="fa fa-ban" aria-hidden="true"/>
   </button>
};

(:~
 : The summary section.
 :)
declare function local:summary($uri as xs:string)
   as element()+
{
   <h3>Summary</h3>,
   <p/>,
   <table class="table table-bordered">
      <tbody>
         <tr>
            <th>Type</th>
            <td> {
               let $doc := fn:doc($uri)
               return
                  if ( fn:empty($doc/node()[2]) and bin:is-json($doc/node()) ) then
                     'JSON'
                  else if ( fn:exists($doc/*) ) then
                     'XML'
                  else if ( fn:exists($doc/text()) ) then
                     'Text'
                  else
                     'Binary'
            }
            </td>
         </tr>
         <tr>
            <th>URI</th>
            <td><code>{ $uri }</code></td>
         </tr>
         <tr>
            <th>Forest</th>
            <td>{ xdmp:forest-name(xdmp:document-forest($uri)) }</td>
         </tr>
         <tr>
            <th>Quality</th>
            <td>{ xdmp:document-get-quality($uri) }</td>
         </tr>
      </tbody>
   </table>
};

(:~
 : The content section.
 :)
declare function local:content($uri as xs:string, $dir as xs:string?, $root as xs:string?, $sep as xs:string?)
   as element()+
{
   <h3>Content</h3>,
   <p>You can <a href="bin?uri={ fn:encode-for-uri($uri) }">download</a> the document.</p>,
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

      if ( fn:empty($doc/node()[2]) and bin:is-json($doc/node()) ) then (
         v:edit-json($doc, $id, $uri, $dir, $root, $sep, ())
      )
      else if ( fn:exists($doc/*) ) then (
         v:edit-xml($doc, $id, $uri, $dir, $root, $sep, ())
      )
      else if ( fn:exists($doc/text()) and fn:empty($doc/node()[2]) ) then (
         (: TODO: Use the internal MarkLogic way to recognize XQuery modules? :)
         let $mode := ( 'xquery'[fn:matches($uri, '\.xq[ylm]?$')],
                        'javascript'[fn:ends-with($uri, '.sjs')],
                        'json'[fn:ends-with($uri, '.json')],
                        'text' )[1]
         return
            v:edit-text($doc/text(), $mode, $id, $uri, $dir, $root, $sep, ())
      )
      else (
         <p>Binary document display not supported.</p>
         (:
         TODO: Implement binary doc deletion, without the ACE editor to hold the
         document URI...  Actually, should be easy to change using the ID, and
         use the URI instead...
         <button class="btn btn-outline-danger" onclick='emlc.deleteDoc("{ $id }");'>
            Delete
         </button>
         :)
      ),
   <p/>
};

(:~
 : The collections section.
 :)
declare function local:collections(
   $db  as element(a:database),
   $uri as xs:string,
   $sep as xs:string?
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
                     <td>{ v:coll-link('', $c) }</td>
                     <td> {
                        v:inline-form('../../tools/del-coll', (
                           v:input-hidden('collection', $c),
                           v:input-hidden('uri', $uri),
                           v:input-hidden('database', $db/@id),
                           v:input-hidden('redirect', 'true'),
                           local:remove-button()))
                     }
                     </td>
                  </tr>
            }
            </tbody>
         </table>,
   v:form('../../tools/add-coll', (
      v:input-text('collection', 'Add collection', 'The collection URI to add the document to'),
      v:input-hidden('uri', $uri),
      v:input-hidden('database', $db/@id),
      v:input-hidden('redirect', 'true'),
      (: TODO: Replace with a Bootstrap character icon... :)
      v:submit('Add')))
};

(:~
 : The metadata section.
 :)
declare function local:metadata(
   $db  as element(a:database),
   $uri as xs:string
) as element()+
{
   <h3>Metadata</h3>,
   let $mdata := xdmp:document-get-metadata($uri)
   let $keys  := $mdata ! map:keys(.)
   return
      if ( fn:empty($keys) ) then
         <p>This document does not have any metadata.</p>
      else
         <table class="table table-bordered datatable">
            <thead>
               <th>Name</th>
               <th>Value</th>
               <th>Remove</th>
            </thead>
            <tbody> {
               for $key in $keys
               order by $key
               return
                  <tr>
                     <td>{ $key }</td>
                     <td>{ map:get($mdata, $key) }</td>
                     <td> {
                        v:inline-form('../../tools/del-meta', (
                           <input type="hidden" name="key"      value="{ $key }"/>,
                           <input type="hidden" name="uri"      value="{ $uri }"/>,
                           <input type="hidden" name="database" value="{ $db/@id }"/>,
                           <input type="hidden" name="redirect" value="true"/>,
                           local:remove-button()))
                     }
                     </td>
                  </tr>
            }
            </tbody>
         </table>,
   v:form('../../tools/add-meta', (
      v:input-text('key',   'Metadata key',   'The name of the metadata to set (or override)'),
      v:input-text('value', 'Metadata value', 'The value of the metadata'),
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
   $db  as element(a:database),
   $uri as xs:string
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
                        v:inline-form('../../tools/del-perm', (
                           <input type="hidden" name="capability" value="{ $capability }"/>,
                           <input type="hidden" name="role"       value="{ $role }"/>,
                           <input type="hidden" name="uri"        value="{ $uri }"/>,
                           <input type="hidden" name="database"   value="{ $db/@id }"/>,
                           <input type="hidden" name="redirect"   value="true"/>,
                           local:remove-button()))
                     }
                     </td>
                  </tr>
            }
            </tbody>
         </table>,
   <p>Add a permission:</p>,
   <form class="form-inline" action="../../tools/add-perm" method="post">
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
      <span>  </span>
      <button type="submit" class="btn btn-outline-secondary">Add</button>
   </form>
};

(:~
 : The triples section.
 :)
declare function local:triples(
   $uri   as xs:string,
   $decls as element(c:decl)*
) as element()+
{
   <h3>Triples</h3>,
   let $triples := cts:triples((), (), (), (), (), cts:document-query($uri))
   let $section := function($extract, $kind) {
            let $rdftype := sem:iri(triples:rdf('type'))
            let $iris    := fn:distinct-values($triples ! $extract(.)[. instance of sem:iri])
            return
               if ( fn:exists($iris) ) then (
                  <p>Every <b>{ $kind }</b> appearing in triples from this document:</p>,
                  <ul> {
                     for $iri    in $iris
                     let $type   := $triples[$extract(.)[. instance of sem:iri] eq $iri][sem:triple-predicate(.) eq $rdftype]
                     let $linker := (v:class-link#3[$kind eq 'object'][fn:exists($type)], v:rsrc-link#3)[1]
                     let $link   := $linker('triples', $iri, $decls)
                     order by $link
                     return
                        <li>{ $link }</li>
                  }
                  </ul>
               )
               else (
                  <p>No resource appear as <b>{ $kind }</b>, in triples from this document
                     (including from TDE).</p>
               )
         }
   return
      if ( fn:exists($triples) ) then (
         $section(sem:triple-subject#1, 'subject'),
         $section(sem:triple-object#1,  'object')
      )
      else (
         <p>This document does not contain any triple (including from TDE).</p>
      )
};

let $name   := t:mandatory-field('name')
let $uri    := t:mandatory-field('uri')
let $prefix := t:optional-field('prefix', ())
return
   v:console-page(
      '../../',
      'db',
      'Browse documents',
      function() {
         v:ensure-db($name, function($db) {
            let $decls   := dbc:config-triple-prefixes($db)
            let $schemes := dbc:config-uri-schemes($db)
            let $uri     := dbc:resolve($uri, $prefix, $schemes)
            return
               t:query($db, function() {
                  local:page($db, $uri, $schemes, $decls)
               })
         })
      },
      (<lib>emlc.ace</lib>,
       <lib>emlc.browser</lib>))
