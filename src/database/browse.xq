xquery version "3.0";

import module namespace a = "http://expath.org/ns/ml/console/admin" at "../lib/admin.xql";
import module namespace t = "http://expath.org/ns/ml/console/tools" at "../lib/tools.xql";
import module namespace v = "http://expath.org/ns/ml/console/view"  at "../lib/view.xql";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare namespace c   = "http://expath.org/ns/ml/console";
declare namespace err = "http://www.w3.org/2005/xqt-errors";
declare namespace cts = "http://marklogic.com/cts";

declare variable $path_ := t:optional-field('path', ())[.];
declare variable $path  := if ( fn:starts-with($path_, '/http://') ) then fn:substring($path_, 2) else $path_;

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
   return (
      (: TODO: In this case, we should NOT return "200 OK". :)
      if ( fn:empty($db) ) then
         <p><b>Error</b>: The database "<code>{ $id-str }</code>" does not exist.</p>
      else if ( fn:exists($init) ) then
         let $relative := 'browse' || '/'[fn:not(fn:starts-with($init, '/'))] || $init
         return (
            v:redirect($relative),
            <p>You are being redirected to <a href="{ $relative }">this page</a>...</p>
         )
      else if ( fn:empty($path) ) then (
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
      )
      else if ( fn:matches($path, '^http://[^/]+/$') ) then (
         local:display-list($id, $path, fn:false()),
         <p>Go up to the <a href="../../../../browse">browse page</a>.</p>
      )
      else if ( $path eq '/' ) then (
         local:display-list($id, $path, fn:false()),
         <p>Go up to the <a href="../browse">browse page</a>.</p>
      )
      else (
         local:display-list($id, $path, fn:true())
      )
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
            if ( $p eq $path ) then (
            )
            else if ( fn:ends-with($p, '/') ) then (
               $path,
               fn:tokenize($p, '/')[fn:last() - 1] ! <a href="{ . }/">{ . }</a>,
               '/'
            )
            else (
               $p
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
