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

declare variable $path := local:get-param-path();

(:~
 : The page, in case the DB does not exist.
 :)
declare function local:get-param-path()
   as xs:string
{
   let $path := t:optional-field('path', ())[.]
   return
      if ( fn:starts-with($path, '/http://') ) then
         fn:substring($path, 2)
      else
         $path
};

(:~
 : The page content, in case the DB does not exist.
 :)
declare function local:page--no-db($id-str as xs:string)
   as element(h:p)
{
   <p><b>Error</b>: The database "<code>{ $id-str }</code>" does not exist.</p>
};

(:~
 : The page content, in case of an init-path param.
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
 :)
declare function local:page--empty-path($id as xs:unsignedLong)
   as element()+
{
   <p>Choose the root to navigate:</p>,
   <ul> {
      for $a in
            a:eval-on-database(
               $id,
               'declare variable $fun  external;
                <a href="browse/">/</a>[fn:exists($fun("/", 1))],
                $fun("http://", 1) ! <a href="browse/{ . }">{ . }</a>',
               (fn:QName('', 'fun'),  local:get-children#2))
      return
         <li>{ $a }</li>
   }
   </ul>,
   <p>Go up to <a href="../../tools">tools</a>.</p>
};

(:~
 : The page content, in case of displaying a root dir (like '/' or 'http://example.org/'.)
 :)
declare function local:page--root($id as xs:unsignedLong, $up as xs:string)
   as element()+
{
   local:display-list($id, $path, fn:false()),
   <p>Go up to the <a href="{ $up }">browse page</a>.</p>
};

(:~
 : The page content, in case of displaying a (non-root) dir.
 :)
declare function local:page--dir($id as xs:unsignedLong)
   as element()+
{
   local:display-list($id, $path, fn:true())
};

(:~
 : The page content, in case of displaying a document.
 :)
declare function local:page--doc()
   as element()+
{
   <p><b>TODO</b>: Editing document not supported yet...</p>,
   <p>Go up to the parent directory: {
      let $toks := fn:tokenize($path, '/')
      return (
         fn:string-join($toks[fn:position() lt fn:last() - 1], '/') || '/',
         <a href=".">{ $toks[fn:last() -1 ] }</a>,
         '/'
      )
   }.</p>,

   <table class="sortable">
      <thead>
         <th>Name</th>
         <th>Value</th>
      </thead>
      <tbody>
         <tr>
            <td>URI</td>
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

   <h4>Content</h4>,
   v:display-xml(fn:doc($path)/*),

   <h4>Properties</h4>,
   let $props := xdmp:document-properties($path)
   return
      if ( fn:exists($props) ) then
         v:display-xml($props/*)
      else
         <p>This document does not have any property.</p>,

   <h4>Permissions:</h4>,
   let $perms := xdmp:document-get-permissions($path)
   return
      if ( fn:exists($perms) ) then
         v:display-xml(<permissions xmlns="">{ $perms }</permissions>)
      else
         <p>This document does not have any permission.</p>
};

(:~
 : The overall page function.
 :)
declare function local:page()
   as element()+
{
   (: the database :)
   let $id-str := t:mandatory-field('id')
   let $id     := xs:unsignedLong($id-str)
   let $db     := a:get-database($id)
   (: the init-path field :)
   let $init   := t:optional-field('init-path', ())[.]
   return
      (: TODO: In this case, we should NOT return "200 OK". :)
      if ( fn:empty($db) ) then (
         local:page--no-db($id-str)
      )
      else if ( fn:exists($init) ) then (
         local:page--init-path($init)
      )
      else if ( fn:empty($path) ) then (
         local:page--empty-path($id)
      )
      else if ( fn:matches($path, '^http://[^/]+/$') ) then (
         local:page--root($id, '../../../../browse')
      )
      else if ( $path eq '/' ) then (
         local:page--root($id, '../browse')
      )
      else if ( fn:ends-with($path, '/') ) then (
         local:page--dir($id)
      )
      else (
         local:page--doc()
      )
};

declare function local:get-children(
   $base  as xs:string,
   $level as item()
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
      distinct-values(
         cts:uri-match($uri-match) ! replace(., $regex, '$1'))
};

(:~
 : TODO: Document... (especially the fact it accesses the entire URI index,
 : should be a problem with large databases, with a shit loads of documents.
 : TODO: The details of how to retrieve the children must be in lib/admin.xql.
 :)
declare function local:display-list($db as xs:unsignedLong, $path as xs:string, $parent as xs:boolean)
   as element()+
{
   <p>Content of "{ $path }".</p>,
   <ul> {
      if ( $parent ) then
         <li><a href="../">..</a>/</li>
      else
         (),
      for $p in 
            a:eval-on-database(
               $db,
               'declare variable $fun  external;
                declare variable $path external;
                $fun($path, 1)',
               (fn:QName('', 'fun'),  local:get-children#2,
                fn:QName('', 'path'), $path))
      let $li :=
            (: current dir :)
            if ( $p eq $path ) then (
            )
            (: subdir :)
            else if ( fn:ends-with($p, '/') ) then (
               $path,
               fn:tokenize($p, '/')[fn:last() - 1] ! <a href="{ . }/">{ . }</a>,
               '/'
            )
            (: file children :)
            else (
               $path,
               fn:tokenize($p, '/')[fn:last()] ! <a href="{ . }">{ . }</a>
            )
      order by $p
      return
         if ( fn:exists($li) ) then
            <li>{ $li }</li>
         else
            ()
   }
   </ul>
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
return
   v:console-page($root, 'tools', 'Browse database', local:page#0)
