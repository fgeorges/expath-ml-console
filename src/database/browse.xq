xquery version "3.0";

import module namespace a = "http://expath.org/ns/ml/console/admin" at "../lib/admin.xql";
import module namespace t = "http://expath.org/ns/ml/console/tools" at "../lib/tools.xql";
import module namespace v = "http://expath.org/ns/ml/console/view"  at "../lib/view.xql";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare namespace c   = "http://expath.org/ns/ml/console";
declare namespace err = "http://www.w3.org/2005/xqt-errors";

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
      (: TODO: In those first few cases, we should NOT return "200 OK". :)
      if ( fn:empty($db) ) then
         <p><b>Error</b>: The database "<code>{ $id-str }</code>" does not exist.</p>
      else if ( fn:not(a:database-dir-creation($db) eq 'automatic') ) then
         <p><b>Error</b>: The database "<code>{ $db/xs:string(a:name) }</code>" does not have
            the option "<code>directory-creation</code>" set to "<code>automatic</code>".
            This is mandatory to be able to browse its content.</p>
      else
         if ( fn:exists($init) ) then
            let $relative := 'browse' || '/'[fn:not(fn:starts-with($init, '/'))] || $init
            return (
               v:redirect($relative),
               <p>You are being redirected to <a href="{ $relative }">this page</a>...</p>
            )
         else if ( fn:empty($path) ) then
            <p>
               <form method="post" action="browse" enctype="multipart/form-data">
                  <span>Choose the root to navigate (e.g. "<code>/</code>" or
                     "<code>http://example.com/</code>"):</span>
                  <br/>
                  <br/>
                  <input type="text" name="init-path" size="50"/>
                  <input type="submit" value="Browse"/>
               </form>
            </p>
         else if ( fn:starts-with($path, 'http://') ) then
            <p>Go up to the <a href="../../../../browse">browse page</a>.</p>
         else if ( $path eq '/' ) then
            <p>Go up to the <a href="../browse">browse page</a>.</p>
         else
            <p>Go up to the <a href="../">parent directory "{ $path }"</a>.</p>
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
