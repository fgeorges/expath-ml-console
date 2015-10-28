xquery version "3.0";

import module namespace a = "http://expath.org/ns/ml/console/admin" at "../lib/admin.xql";
import module namespace t = "http://expath.org/ns/ml/console/tools" at "../lib/tools.xql";
import module namespace v = "http://expath.org/ns/ml/console/view"  at "../lib/view.xql";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare namespace h    = "http://www.w3.org/1999/xhtml";
declare namespace c    = "http://expath.org/ns/ml/console";
declare namespace err  = "http://www.w3.org/2005/xqt-errors";
declare namespace cts  = "http://marklogic.com/cts";
declare namespace xdmp = "http://marklogic.com/xdmp";
declare namespace map  = "http://marklogic.com/xdmp/map";
declare namespace sec  = "http://marklogic.com/xdmp/security";

declare variable $path := local:get-param-path();

declare variable $root := local:get-root($path);

(: Fixed page size for now. :)
declare variable $page-size := 100;

(:~
 : The param "path", if any.
 :)
declare function local:get-param-path()
   as xs:string?
{
   let $path := t:optional-field('path', ())[.]
   return
      if ( fn:starts-with($path, '/http://') ) then
         fn:substring($path, 2)
      else
         $path
};

(:~
 : The path to the webapp root, relative to current $path.
 :)
declare function local:get-root($path as xs:string?)
   as xs:string
{
   if ( fn:empty($path) ) then
      './'
   else
      let $toks  := fn:tokenize($path, '/')
      let $count := fn:count($toks) + (1[fn:starts-with($path, '/')], 2)[1]
      return
         t:make-string('../', $count)
};

(:~
 : The page content, in case the DB does not exist.
 :)
declare function local:page--no-db($id as xs:unsignedLong)
   as element(h:p)
{
   <p><b>Error</b>: The database "<code>{ $id }</code>" does not exist.</p>
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
 :)
declare function local:page--empty-path($db as element(a:database))
   as element()+
{
   <p>Database: "{ xs:string($db/a:name) }".  Go up to <a href="../../tools">tools</a>.</p>,
   local:create-doc-form($db, ()),
   let $items := (
         <li>
            <a href="browse/">
               <span class="glyphicon glyphicon-collapse-down" aria-hidden="true"/>
            </a>
            /
         </li>[fn:exists(local:get-children("/", 1, 1))],
         (: TODO: Display in case there are more roots than $page-size! :)
         local:get-children("http://", 1, 1) ! <li>http://<a href="browse/{ . }"> {
            fn:substring(., 8, fn:string-length(.) - 8)
         }</a>/</li>
      )
   return
      if ( fn:exists($items) ) then (
         <p>Choose the root to navigate:</p>,
         <ul> {
            $items
         }
         </ul>
      )
      else (
         <p>The database is empty.</p>
      )
};

(:~
 : The page content, in case of displaying a root dir (like '/' or 'http://example.org/'.)
 :)
declare function local:page--root($db as element(a:database), $up as xs:string, $start as xs:integer)
   as element()+
{
   <p>Database: "{ xs:string($db/a:name) }".  Go up to the <a href="{ $up }">browse page</a>.</p>,
   local:display-list($db, $path, $start)
};

(:~
 : The page content, in case of displaying a (non-root) dir.
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
   local:up-to-browse($db/a:name, $path),
   local:display-list($db, $path, $start)
};

(:~
 : The page content, in case of displaying a document.
 :)
declare function local:page--doc($db as element(a:database))
   as element()+
{
   local:up-to-browse($db/a:name, $path),
   <p>In directory { local:uplinks($path, fn:false()) }.</p>,

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
            <td>{ $path }</td>
         </tr>
         <tr>
            <td>Collections</td>
            <td> {
               xdmp:document-get-collections($path) ! (., <br/>)
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
   let $doc   := fn:doc($path)/node()
   let $id    := fn:generate-id($doc)
   let $count := fn:count(fn:tokenize($path, '/')) - (1[fn:starts-with($path, '/')], 0)[1]
   let $up    := t:make-string('../', $count)
   return
      typeswitch ( $doc )
         case element() return (
            v:edit-xml($doc, $id, $path, $up || 'save-doc'),
            <button class="btn btn-default" onclick='saveDoc("{ $id }");'>Save</button>
         )
         case text() return (
            (: TODO: Use the internal MarkLogic way to recognize XQuery modules? :)
            let $mode := ('xquery'[fn:matches($path, '\.xq[ylm]?$')], 'javascript'[fn:ends-with($path, '.sjs')], 'text')[1]
            return (
               v:edit-text($doc, $mode, $id, $path, $up || 'save-text'),
               <button class="btn btn-default" onclick='saveDoc("{ $id }");'>Save</button>
            )
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
                        v:inline-form($root || 'tools/del-perm', (
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
      <input type="hidden" name="uri"      value="{ $path }"/>
      <input type="hidden" name="database" value="{ $db/@id }"/>
      <input type="hidden" name="redirect" value="true"/>
      <button type="submit" class="btn btn-default">Add</button>
   </form>
};

(:~
 : The overall page function.
 :)
declare function local:page(
   $id     as xs:unsignedLong,
   $path   as xs:string?,
   $init   as xs:string?,
   $start  as xs:integer
) as element()+
{
   let $db := a:get-database($id)
   return
      (: TODO: In this case, we should NOT return "200 OK". :)
      if ( fn:empty($db) ) then (
         local:page--no-db($id)
      )
      else if ( fn:exists($init) ) then (
         local:page--init-path($init)
      )
      else if ( fn:empty($path) ) then (
         local:page--empty-path($db)
      )
      else if ( fn:matches($path, '^http://[^/]+/$') ) then (
         local:page--root($db, '../../../../browse', $start)
      )
      else if ( $path eq '/' ) then (
         local:page--root($db, '../browse', $start)
      )
      else if ( fn:ends-with($path, '/') ) then (
         local:page--dir($db, $start)
      )
      else (
         local:page--doc($db)
      )
};

declare function local:get-children(
   $base  as xs:string,
   $level as item(),
   $start as xs:integer
) as xs:string*
{
   let $uri-match :=
         if ( $base eq '' or ends-with($base, '/') ) then
            $base || '*'
         else
            $base || '/*'
   let $regex-base :=
         if ( $base eq '' or ends-with($base, '/') ) then
            $base
         else
            $base || '/'
   let $depth :=
         if ( string($level) eq 'infinity' ) then
            '*'
         else
            '{' || $level || '}'
   let $remainder :=
         if ( $base eq '' and string($level) eq 'infinity' ) then
            '.+'
         else
            '.*'
   let $regex :=
         '^(' || $regex-base || '([^/]*/)' || $depth || ')' || $remainder || ''
   return
      (: TODO: Why is distinct-valus needed?  Any way to get rid of it? :)
      fn:distinct-values(
         cts:uri-match($uri-match) ! fn:replace(., $regex, '$1'))
         [fn:position() ge $start and fn:position() lt $start + $page-size]
};

(:~
 : Create the "create document" form.
 :)
declare function local:create-doc-form(
   $db   as element(a:database),
   $path as xs:string?
) as element(h:form)
{
   v:form($root || 'tools/insert', (
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
 : TODO: The details of how to retrieve the children must be in lib/admin.xql.
 :)
declare function local:display-list(
   $db    as element(a:database),
   $path  as xs:string,
   $start as xs:integer
) as element()+
{
   local:create-doc-form($db, $path),
   (: Do we really need to filter out "$path"?  Can't we get rid of it in get-children()? :)
   let $children := local:get-children($path, 1, $start)[. ne $path]
   let $count    := fn:count($children)
   let $to       := $start + $count - 1
   return (
      (: display $path, with each part being a link :)
      <p>
         Content of { local:uplinks($path, fn:true()) },
         results { $start } to { $to }{
            t:cond($start gt 1,
               (', ', <a href="./?start={ $start - $page-size }">previous page</a>)),
            t:cond($count eq $page-size,
               (', ', <a href="./?start={ $start + $count }">next page</a>))
         }:
      </p>,
      (: display the list of children themselves :)
      <ul> {
         for $c in $children
         order by $c
         return
            (: subdir :)
            if ( fn:ends-with($c, '/') ) then
               <li>{ fn:tokenize($c, '/')[fn:last() - 1] ! <a href="{ fn:encode-for-uri(.) }/">{ . }</a> }/</li>
            (: file children :)
            else
               <li>{ fn:tokenize($c, '/')[fn:last()] ! <a href="{ fn:encode-for-uri(.) }">{ . }</a> }</li>
      }
      </ul>
   )
};

(:~
 : The "Go up to the browse page" link.  From a dir or file, "/" or "http://".
 :)
declare function local:up-to-browse($db as xs:string, $path as xs:string)
   as element(h:p)
{
   let $toks  := fn:tokenize($path, '/')
   let $count := fn:count($toks) - (1[fn:starts-with($path, '/')], 0)[1]
   return
      <p>Database: "{ $db }".  Go up to the
         <a href="{ t:make-string('../', $count) }browse">browse page</a>.</p>
};

(:~
 : Display the current directory, with each part being a link up to it.
 : 
 : Display the current directory (the parent directory when displaying a file).
 : Each part of the directory is clickable to go up to it in the browser (when
 : displaying a directory, the last part is not clickable, as it is the current
 : dir).
 :
 : The path is within quotes `"`, and contains appropriate text after (and a
 : link up to "/" when the path starts with "/", as it is not convenient to
 : click on such a short text).
 :)
declare function local:uplinks($path as xs:string, $isdir as xs:boolean)
   as node()+
{
   (: The 3 cases must be handled in slightly different ways, because the "go back
      to root" button is not necessary with "http" URIs (just click on the domain
      name part), while it is necessary for "/" URIs (clicking on the "/" is just
      no an option). :)
   if ( $path eq '/' ) then (
      text { '"/"' }
   )
   else if ( fn:starts-with($path, '/') ) then (
      let $toks := fn:tokenize($path, '/')[.]
      return (
         text { '" ' },
         <a href="./{ t:make-string('../', fn:count($toks) - (0[$isdir], 1)[1]) }">
            <span class="glyphicon glyphicon-collapse-up" aria-hidden="true"/>
         </a>,
         text { ' /' },
         local:uplinks-1($toks[fn:position() lt fn:last()], ('../'[$isdir], './')[1]),
         text { $toks[fn:last()] || '/' }[$isdir]
      )
   )
   else if ( fn:starts-with($path, 'http://') ) then (
      let $toks := fn:remove(fn:tokenize($path, '/')[.], 1)
      return (
         text { '"http://' },
         local:uplinks-1($toks[fn:position() lt fn:last()], ('../'[$isdir], './')[1]),
         text { $toks[fn:last()] || '/' }[$isdir],
         text { '"' },
         text { ' (click on a part to travel up the directories)' }[fn:exists($toks[2])]
      )
   )
   else (
      text { '(' },
      <a href="../">go up</a>,
      text { ') "' || $path || '"' }
   )
};

declare function local:uplinks-1($toks as xs:string*, $up as xs:string?)
   as node()*
{
   if ( fn:empty($toks) ) then (
   )
   else (
      local:uplinks-1($toks[fn:position() lt fn:last()], '../' || $up),
      <a href="{ $up }">{ $toks[fn:last()] }</a>,
      text { '/' }
   )
};

(:
browse -> 2
browse/ -> 3
browse/http:/ -> 4
browse/http:// -> 5
browse/http://example.com/ -> 6
:)

let $slashes := if ( fn:empty($path) ) then 0 else fn:count(fn:tokenize($path, '/'))
let $root    := fn:string-join(for $i in 1 to $slashes + 2 return '..', '/') || '/'
let $db-str  := t:mandatory-field('id')
let $db      := xs:unsignedLong($db-str)
let $init    := t:optional-field('init-path', ())[.]
let $start   := xs:integer(t:optional-field('start', 1)[.])
let $params  := 
      map:new((
         map:entry(xdmp:key-from-QName(fn:QName('', 'db')),    $db),
         map:entry(xdmp:key-from-QName(fn:QName('', 'path')),  $path),
         map:entry(xdmp:key-from-QName(fn:QName('', 'init')),  $init),
         map:entry(xdmp:key-from-QName(fn:QName('', 'start')), $start),
         map:entry(xdmp:key-from-QName(fn:QName('', 'fun')),  local:page#4)))
return
   v:console-page($root, 'tools', 'Browse database', function() {
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
