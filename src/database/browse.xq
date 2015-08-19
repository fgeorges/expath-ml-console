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
 : 
 : TODO: Displays only "/" and "http://*/" for now.  Find anything else that
 : ends with a "/" as well.  Maybe even "urn:*:" URIs?
 :)
declare function local:page--empty-path($id as xs:unsignedLong)
   as element()+
{
   <p>Go up to <a href="../../tools">tools</a>.</p>,
   <p>Choose the root to navigate:</p>,
   <ul> {
      a:eval-on-database(
         $id,
         'declare variable $fun  external;
          <li>
             <a href="browse/">/</a>
             (quite short link, innit?, <a href="browse/">click here to go to /</a>)
          </li>[fn:exists($fun("/", 1))],
          $fun("http://", 1) ! <li><a href="browse/{ . }">{ . }</a></li>',
         (fn:QName('', 'fun'),  local:get-children#2))
   }
   </ul>
};

(:~
 : The page content, in case of displaying a root dir (like '/' or 'http://example.org/'.)
 :)
declare function local:page--root($id as xs:unsignedLong, $up as xs:string)
   as element()+
{
   <p>Go up to the <a href="{ $up }">browse page</a>.</p>,
   local:display-list($id, $path)
};

(:~
 : The page content, in case of displaying a (non-root) dir.
 : 
 : TODO: Display whether the directory exists per se in MarkLogic (and its
 : properties if it has any, etc.)
 :)
declare function local:page--dir($id as xs:unsignedLong)
   as element()+
{
   local:up-to-browse($path),
   local:display-list($id, $path)
};

(:~
 : The page content, in case of displaying a document.
 :)
declare function local:page--doc()
   as element()+
{
   local:up-to-browse($path),
   <p>In directory { local:uplinks($path, fn:false()) }.</p>,

   <table class="sortable">
      <thead>
         <th>Name</th>
         <th>Value</th>
      </thead>
      <tbody>
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

   <h4>Content</h4>,
   let $doc   := fn:doc($path)/node()
   let $id    := fn:generate-id($doc)
   let $count := fn:count(fn:tokenize($path, '/')) - (1[fn:starts-with($path, '/')], 0)[1]
   let $up    := t:make-string('../', $count)
   return
      typeswitch ( $doc )
         case element() return (
            v:edit-xml($doc, $id, $path, $up || 'save-doc'),
            <button onclick='saveDoc("{ $id }");'>Save</button>
         )
         case text() return (
            let $mode := ('xquery'[fn:matches($path, '\.xq[ylm]?$')], 'text')[1]
            return (
               v:edit-text($doc, $mode, $id, $path, $up || 'save-text'),
               <button onclick='saveDoc("{ $id }");'>Save</button>
            )
         )
         default return (
            <p>Binary document display not supported.</p>
         ),

   <h4>Properties</h4>,
   let $props := xdmp:document-properties($path)
   return
      if ( fn:exists($props) ) then
         v:display-xml($props/*)
      else
         <p>This document does not have any property.</p>,

   <h4>Permissions</h4>,
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
declare function local:display-list($db as xs:unsignedLong, $path as xs:string)
   as element()+
{
   (: display $path, with each part being a link :)
   <p>Content of { local:uplinks($path, fn:true()) }:</p>,
   (: display the list of children themselves :)
   <ul> {
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
               fn:tokenize($p, '/')[fn:last() - 1] ! <a href="{ . }/">{ . }</a>,
               '/'
            )
            (: file children :)
            else (
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

(:~
 : The "Go up to the browse page" link.  From a dir or file, "/" or "http://".
 :)
declare function local:up-to-browse($path as xs:string)
   as element(h:p)
{
   let $toks  := fn:tokenize($path, '/')
   let $count := fn:count($toks) - (1[fn:starts-with($path, '/')], 0)[1]
   return
      <p>Go up to the <a href="{ t:make-string('../', $count) }browse">browse page</a>.</p>
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
   (: The 3 cases must be handled in slightly different ways, because "go up to root"
      is not necessary with "http" URIs (just click on the domain name part), while
      it is necessary for "/" URIs (clicking on the "/" is just no an option).
      TODO: Find a better way than the "go to /" link.  Maybe a button? :)
   if ( $path eq '/' ) then (
      text { '"/"' }
   )
   else if ( fn:starts-with($path, '/') ) then (
      let $toks := fn:tokenize($path, '/')[.]
      return (
         text { '"/' },
         local:uplinks-1($toks[fn:position() lt fn:last()], ('../'[$isdir], './')[1]),
         text { $toks[fn:last()] || '/' }[$isdir],
         text { '" (' },
         <a href="{ t:make-string('../', fn:count($toks) - (0[$isdir], 1)[1]) }">go to /</a>,
         text { ', or click on a part to travel up the directories' }[fn:exists($toks[2])],
         text { ')' }
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
return
   v:console-page($root, 'tools', 'Browse database', local:page#0)
