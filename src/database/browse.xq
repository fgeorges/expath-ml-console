xquery version "3.0";

import module namespace b = "http://expath.org/ns/ml/console/browse" at "browse-lib.xql";
import module namespace a = "http://expath.org/ns/ml/console/admin"  at "../lib/admin.xql";
import module namespace t = "http://expath.org/ns/ml/console/tools"  at "../lib/tools.xql";
import module namespace v = "http://expath.org/ns/ml/console/view"   at "../lib/view.xql";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare namespace h    = "http://www.w3.org/1999/xhtml";
declare namespace cts  = "http://marklogic.com/cts";
declare namespace xdmp = "http://marklogic.com/xdmp";
declare namespace map  = "http://marklogic.com/xdmp/map";
declare namespace sec  = "http://marklogic.com/xdmp/security";

declare variable $path := t:optional-field('path', ())[.];

declare variable $db-root     := b:get-db-root($path);
declare variable $webapp-root := $db-root || '../../';

(:~
 : The page content, in case the DB does not exist.
 :)
declare function local:page--no-db($id as xs:unsignedLong)
   as element(h:p)
{
   <p><b>Error</b>: There is no database with the ID <code>{ $id }</code>.</p>
};

(:~
 : The page content, in case the URI lexicon is not enabled on the DB.
 :)
declare function local:page--no-lexicon($db as element(a:database))
   as element(h:p)
{
   <p><b>Error</b>: The URI lexicon is not enabled on the database
      { v:db-link($db-root || 'browse', $db/a:name) }.  It is required to
      browse the directories.</p>
};

(:~
 : The page content, in case of an init-path param.
 :
 : TODO: Is it still used?
 :)
declare function local:page--init-path($init as xs:string)
   as element(h:p)
{
   let $relative := 'browse' || '/'[fn:not(fn:starts-with($init, '/'))] || $init
   return (
      v:redirect($relative),
      <p>You are being redirected to <a href="{ $relative }">this page</a>...</p>
   )
};

(:~
 : The page content, in case of an empty path.
 : 
 : TODO: Displays only "/" and "http://*/" for now.  Find anything else that
 : ends with a "/" as well.  Maybe even "urn:*:" URIs?
 :
 : TODO: Lot of duplicated code with local:display-list(), factorize out?
 :)
declare function local:page--empty-path($db as element(a:database), $start as xs:integer)
   as element()+
{
   <p>Database: { v:db-link('browse', $db/a:name) }</p>,
   local:create-doc-form($db, ()),
   b:display-list(
      (),
      ( '/'[fn:exists(b:get-children-uri('/', 1))],
        b:get-children-uri('http://', 1) ),
      $start,
      function($child as xs:string, $pos as xs:integer) {
         <li>
            <input name="name-{ $pos }"   type="hidden" value="{ $child }"/>
            <input name="delete-{ $pos }" type="checkbox"/>
            { ' ' }
            { v:dir-link('browse/' || $child[. ne '/'], $child) }
         </li>
      },
      function($items as element(h:li)*) {
         if ( fn:exists($items) ) then (
            <p>Choose the root to navigate:</p>,
            v:form(
               '',
               attribute { 'id' } { 'orig-form' },
               <ul style="list-style-type: none"> {
                  $items
               }
               </ul>),
            <button class="btn btn-danger" onclick='deleteUris("orig-form", "hidden-form");'>Delete</button>,
            v:inline-form(
               $db-root || 'bulk-delete',
               (attribute { 'id'    } { 'hidden-form' },
                attribute { 'style' } { 'display: none' }),
               v:input-hidden('back-url', 'browse' || '/'[fn:not(fn:starts-with($path, '/'))] || $path))
         )
         else (
            <p>The database is empty.</p>
         )
      })
};

(:~
 : The page content, in case of displaying a dir.
 : 
 : TODO: Display whether the directory exists per se in MarkLogic (and its
 : properties if it has any, etc.)
 :
 : TODO: Is there a way to detect whether there is a URI Privilege for a specific
 : directory?  A way to say "the creation of docujments in this directory is
 : protected by privilege xyz..."
 :)
declare function local:page--dir($db as element(a:database), $start as xs:integer)
   as element()+
{
   <p>Database: { v:db-link($db-root || 'browse', $db/a:name) }</p>,
   local:display-list($db, $path, $start)
};

(:~
 : The page content, in case of displaying a document.
 :)
declare function local:page--doc($db as element(a:database))
   as element()+
{
   local:up-to-browse($db/a:name, $path),
   <p>In directory: { b:uplinks($path, fn:false()) }</p>,
   if ( fn:not(fn:doc-available($path)) ) then (
      <p>The document <code>{ $path } </code> does not exist.</p>
   )
   else (
      <h3>Summary</h3>,
      <table class="table table-bordered">
         <thead>
            <th>Name</th>
            <th>Value</th>
         </thead>
         <tbody>
            <tr>
               <td>Type</td>
               <td> {
                  typeswitch ( fn:doc($path)/node() )
                     case element() return 'XML'
                     case text()    return 'Text'
                     default        return 'Binary'
               }
               </td>
            </tr>
            <tr>
               <td>Document URI</td>
               <td> {
                  v:doc-link(fn:encode-for-uri(fn:tokenize($path, '/')[fn:last()]), $path)
               }
               </td>
            </tr>
            <tr>
               <td>Collections</td>
               <td> {
                  for $c in xdmp:document-get-collections($path)
                  return
                     <p style="margin-bottom: 5px"> {
                        v:coll-link($db-root || 'colls?coll=' || fn:encode-for-uri($c), $c)
                     }
                     </p>
               }
               </td>
            </tr>
            <tr>
               <td>Forest</td>
               <td>{ xdmp:forest-name(xdmp:document-forest($path)) }</td>
            </tr>
            <tr>
               <td>Quality</td>
               <td>{ xdmp:document-get-quality($path) }</td>
            </tr>
         </tbody>
      </table>,

      <h3>Content</h3>,
      let $doc := fn:doc($path)/node()
      let $id  := fn:generate-id($doc)
      return
         typeswitch ( $doc )
            case element() return (
               v:edit-xml($doc, $id, $path, $db-root)
            )
            case text() return (
               (: TODO: Use the internal MarkLogic way to recognize XQuery modules? :)
               let $mode := ( 'xquery'[fn:matches($path, '\.xq[ylm]?$')],
                              'javascript'[fn:ends-with($path, '.sjs')],
                              'text' )[1]
               return
                  v:edit-text($doc, $mode, $id, $path, $db-root)
            )
            default return (
               <p>Binary document display not supported.</p>
            ),

      <h3>Properties</h3>,
      let $props := xdmp:document-properties($path)
      return
         if ( fn:exists($props) ) then
            v:display-xml($props/*)
         else
            <p>This document does not have any property.</p>,

      <h3>Permissions</h3>,
      let $perms := xdmp:document-get-permissions($path)
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
                           v:inline-form($webapp-root || 'tools/del-perm', (
                              <input type="hidden" name="capability" value="{ $capability }"/>,
                              <input type="hidden" name="role"       value="{ $role }"/>,
                              <input type="hidden" name="uri"        value="{ $path }"/>,
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
      <form class="form-inline" action="{ $webapp-root }tools/add-perm" method="post">
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
         <input type="hidden" name="uri"      value="{ $path }"/>
         <input type="hidden" name="database" value="{ $db/@id }"/>
         <input type="hidden" name="redirect" value="true"/>
         <button type="submit" class="btn btn-default">Add</button>
      </form>
   )
};

(:~
 : The overall page function.
 :)
declare function local:page(
   $id    as xs:unsignedLong,
   $path  as xs:string?,
   $init  as xs:string?,
   $start as xs:integer
) as element()+
{
   let $db := a:get-database($id)
   return
      (: TODO: In this case, we should NOT return "200 OK". :)
      if ( fn:empty($db) ) then (
         local:page--no-db($id)
      )
      (: TODO: In this case, we should NOT return "200 OK". :)
      else if ( fn:not($db/a:lexicons/xs:boolean(a:uri)) ) then (
         local:page--no-lexicon($db)
      )
      else if ( fn:exists($init) ) then (
         local:page--init-path($init)
      )
      else if ( fn:empty($path) ) then (
         local:page--empty-path($db, $start)
      )
      else if ( fn:ends-with($path, '/') ) then (
         local:page--dir($db, $start)
      )
      else (
         local:page--doc($db)
      )
};

(:~
 : Create the "create document" form.
 :)
declare function local:create-doc-form(
   $db   as element(a:database),
   $path as xs:string?
) as element(h:form)
{
   v:form($webapp-root || 'tools/insert', (
      v:input-text('uri', 'Create document', 'Document URI (relative to this directory)'),
      v:input-select('format', 'Format', (
         v:input-option('xml',    'XML'),
         v:input-option('text',   'Text'),
         v:input-option('binary', 'Binary'))),
      if ( fn:exists($path) ) then v:input-hidden('prefix', $path) else (),
      v:input-hidden('database', $db/@id),
      v:input-hidden('redirect', 'true'),
      v:input-hidden('file',     '&lt;hello&gt;World!&lt;/hello&gt;'),
      v:submit('Create')))
};

(:~
 : TODO: Document... (especially the fact it accesses the entire URI index,
 : should be a problem with large databases, with a shit loads of documents.
 :
 : TODO: The details of how to retrieve the children must be in lib/admin.xql.
 :
 : TODO: Lot of duplicated code with local:page--empty-path(), factorize out?
 :)
declare function local:display-list(
   $db    as element(a:database),
   $path  as xs:string,
   $start as xs:integer
) as element()+
{
   local:create-doc-form($db, $path),
   b:display-list(
      $path,
      (: Do we really need to filter out "$path"?  Can't we get rid of it in get-children-uri()? :)
      b:get-children-uri($path, $start)[. ne $path],
      $start,
      function($child as xs:string, $pos as xs:integer) {
         let $dir  := fn:ends-with($child, '/')
         let $name := fn:tokenize($child, '/')[fn:last() - (1[$dir], 0)[1]]
         return
            <li>
               <input name="name-{ $pos }"   type="hidden" value="{ $child }"/>
               <input name="delete-{ $pos }" type="checkbox"/>
               { ' ' }
               {
                  if ( $dir ) then
                     v:dir-link(fn:encode-for-uri($name) || '/', $name || '/')
                  else
                     v:doc-link(fn:encode-for-uri($name), $name)
               }
            </li>
      },
      function($items as element(h:li)+) {
         (: display the list of children themselves :)
         v:form(
            '',
            attribute { 'id' } { 'orig-form' },
            <ul style="list-style-type: none"> {
               $items
            }
            </ul>),
         <button class="btn btn-danger" onclick='deleteUris("orig-form", "hidden-form");'>Delete</button>,
         v:inline-form(
            $db-root || 'bulk-delete',
            (attribute { 'id'    } { 'hidden-form' },
             attribute { 'style' } { 'display: none' }),
            v:input-hidden('back-url', 'browse' || '/'[fn:not(fn:starts-with($path, '/'))] || $path))
      })
};

(:~
 : The "Go up to the browse page" link.  From a dir or file, "/" or "http://".
 :)
declare function local:up-to-browse($db as xs:string, $path as xs:string)
   as element(h:p)
{
   let $toks  := fn:tokenize($path, '/')
   let $count := fn:count($toks) - (1[fn:starts-with($path, '/')], 0)[1]
   let $up    := t:make-string('../', $count) || 'browse'
   return
      <p>Database: { v:db-link($up, $db) }</p>
};

(:
browse -> 2
browse/ -> 3
browse/http:/ -> 4
browse/http:// -> 5
browse/http://example.com/ -> 6
:)

let $slashes := if ( fn:empty($path) ) then 0 else fn:count(fn:tokenize($path, '/'))
let $db-str  := t:mandatory-field('id')
let $db      := xs:unsignedLong($db-str)
let $init    := t:optional-field('init-path', ())[.]
let $start   := xs:integer(t:optional-field('start', 1)[.])
let $params  := 
      map:new((
         map:entry('db',    $db),
         map:entry('path',  $path),
         map:entry('init',  $init),
         map:entry('start', $start),
         map:entry('fun',   local:page#4)))
return
   v:console-page(
      $webapp-root,
      'browser',
      'Browse documents',
      function() {
         a:eval-on-database(
            $db,
            'declare variable $db    external;
             declare variable $start external;
             declare variable $path  external := ();
             declare variable $init  external := ();
             declare variable $fun   external;
             $fun($db, $path, $init, $start)',
            $params)
      })
