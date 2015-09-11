xquery version "3.0";

(:~
 : Insert a document or a directory into a specific database.
 :
 : Accept the following request fields for a file (all mandatory except
 : prefix, override and redirect):
 :   - database: the ID of the target database
 :   - uri: the target URI where to insert the file
 :   - prefix: concatenated to $uri if present, to get the entire doc URI
 :   - file: the file itself
 :   - format: the format of the file (either 'xml', 'text' or 'binary')
 :   - override: allow overriding an existing file (false by default)
 :   - redirect: display the doc on the "browse" area (false by default)
 :
 : Accept the following request fields for a directory (all mandatory except
 : filter):
 :   - database: the ID of the target database
 :   - uri: the target URI where to insert the directory
 :   - dir: the name of the directory itself (must be on the same machine)
 :   - include: a regex filename pattern, for files to be included
 :   - exclude: a regex filename pattern, for files to be excluded
 :
 : Accept the following request fields for a zipped directory (all mandatory):
 :   - database: the ID of the target database
 :   - uri: the target URI where to insert the directory
 :   - zipdir: the ZIP file itself
 :
 : TODO: Split into 3 different queries for the 3 cases above...?
 :)

import module namespace a = "http://expath.org/ns/ml/console/admin"  at "../lib/admin.xql";
import module namespace b = "http://expath.org/ns/ml/console/binary" at "../lib/binary.xql";
import module namespace t = "http://expath.org/ns/ml/console/tools"  at "../lib/tools.xql";
import module namespace v = "http://expath.org/ns/ml/console/view"   at "../lib/view.xql";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare namespace prop = "http://marklogic.com/xdmp/property";
declare namespace xdmp = "http://marklogic.com/xdmp";

(:~
 : The overall page function.
 :)
declare function local:page()
   as element()+
{
   (: TODO: Check the params are there, and validate them... :)
   let $file   := t:optional-field('file', ())
   let $dir    := t:optional-field('dir', ())
   let $zipdir := t:optional-field('zipdir', ())
   let $count  := fn:count(($file, $dir, $zipdir))
   return
      if ( $count ne 1 ) then
         <p><b>Error</b>: Exactly 1 parameter out of "file", "dir" and "zipdir"
            should be provided. Got { $count } of them.  File is "{ $file }", dir
            is "{ $dir }" and zipdir is "{ $zipdir }".</p>
      else if ( fn:exists($file) ) then
         local:handle-file($file)
      else if ( fn:exists($dir) ) then
         local:handle-dir($dir)
      else
         local:handle-zipdir($zipdir),
   <p>Back to <a href="docs">document manager</a>.</p>
};

(:~
 : Handle the case "insert a file".
 :)
declare function local:handle-file($file as item())
{
   let $db-id    := xs:unsignedLong(t:mandatory-field('database'))
   let $uri      := t:mandatory-field('uri')
   let $format   := t:mandatory-field('format')
   let $prefix   := t:optional-field('prefix', ())[.]
   let $override := xs:boolean(t:optional-field('override', 'false'))
   let $redirect := xs:boolean(t:optional-field('redirect', 'false'))
   let $doc-uri  := if ( fn:exists($prefix) ) then $prefix || $uri else $uri
   return
      if ( fn:doc-available($doc-uri) and fn:not($override) ) then
         <p><b>Error</b>: File already exists at "{ $doc-uri }".</p>
      else
         let $node   := local:get-node($file, $format)
         let $result := a:insert-into-database($db-id, $doc-uri, $node)
         return
            if ( $redirect ) then
               v:redirect(
                  '../db/' || $db-id || '/browse'
                  || '/'[fn:not(fn:starts-with($doc-uri, '/'))]
                  || fn:string-join(fn:tokenize($doc-uri, '/') ! fn:encode-for-uri(.), '/'))
            else
               <p>File succesfully inserted at "{ $result }" as "{ $format }".</p>
};

(:~
 : Return () if $uri does NOT exist, and an error message in case it does exist.
 :
 : A directory is considered to be existing if it contains the property
 : `prop:directory` in its document properties, or if there is any document in
 : that directory or any descendent.
 :
 : FIXME: I think this is wrong!  The functions `xdmp:document-properties`,
 : `fn:doc-available` and `xdmp:directory` should be evaluated on the target
 : database, not called directly here! Same error in `local:handle-file`.
 : (or did I miss something?)
 :)
declare function local:dir-exists($uri as xs:string)
   as element(p)?
{
   let $props := xdmp:document-properties($uri)
   return
      if ( fn:not(fn:ends-with($uri, '/')) ) then
         <p><b>Error</b>: Directory name must end with a slash, but you provided "{ $uri }".</p>
      else if ( fn:exists($props/prop:properties/prop:directory) ) then
         <p><b>Error</b>: Directory already exists at "{ $uri }".</p>
      else if ( fn:exists($props) ) then
         <p><b>Error</b>: Directory already exists at "{ $uri }".</p>
      else if ( fn:doc-available($uri) ) then
         <p><b>Error</b>: Directory already exists at "{ $uri }".</p>
      else if ( fn:exists(xdmp:directory($uri, 'infinity')) ) then
         <p><b>Error</b>: Directory already exists at "{ $uri }".</p>
      else
         ()
};

(:~
 : Handle the case "insert a directory".
 :)
declare function local:handle-dir($dir as xs:string)
{
   let $db-id   := xs:unsignedLong(t:mandatory-field('database'))
   let $uri     := t:mandatory-field('uri')
   let $include := t:optional-field('include', ())
   let $exclude := t:optional-field('exclude', ())
   let $exists  := local:dir-exists($uri)
   return
      if ( fn:exists($exists) ) then
         $exists
      else
         let $result := a:load-dir-into-database($db-id, $uri, $dir, $include, $exclude)
         return
            <p>Directory succesfully uploaded at "{ $result }" from "{ $dir }".</p>
};

(:~
 : Handle the case "insert a zipped directory".
 :)
declare function local:handle-zipdir($zip (: as binary() :))
{
   let $db-id  := xs:unsignedLong(t:mandatory-field('database'))
   let $uri    := t:mandatory-field('uri')
   let $exists := local:dir-exists($uri)
   return
      if ( fn:exists($exists) ) then
         $exists
      else
         let $result := a:load-zipdir-into-database($db-id, $uri, $zip)
         return
            <p>Directory succesfully uploaded at "{ $result }" from ZIP file.</p>
};

(:~
 : Check the type of $file, accordingly to $format, and possibly transform it.
 :
 : If $format is 'text', $file must be a text node within a doc node, or it
 :   must be a binary node, in which case it is decoded (TODO: Still TBD.)
 : If $format is 'binary', $file must be a binary node.
 : If $format is 'xml', $file must be an element node within a doc node (which
 :   seems is never the case with MarkLogic), or it must be a text node within
 :   a doc node, in which case it is parsed. (TODO: What if it is binary?
 :   Probably decode it then parse it...)
 :)
declare function local:get-node($file as item(), $format as xs:string)
   as node()
{
   if ( $format eq 'text' ) then
      if ( $file instance of xs:string ) then
         text { $file }
      else if ( $file instance of document-node() and fn:exists($file/text()) ) then
         $file
      else if ( b:is-binary($file) ) then
         text { xdmp:binary-decode($file, 'utf-8') }
      else
         t:error('INSERT001', 'Text file is not a text node, please report this to the mailing list')
   else if ( $format eq 'binary' ) then
      if ( b:is-binary($file) ) then
         $file
      else
         t:error('INSERT002', 'Binary file is not a binary node, please report this to the mailing list')
   else if ( $format eq 'xml' ) then
      if ( $file instance of xs:string ) then
         xdmp:unquote($file)
      else if ( $file instance of document-node() and fn:exists($file/*) ) then
         $file
      else if ( $file instance of document-node() and fn:exists($file/text()) ) then
         xdmp:unquote($file)
      else if ( b:is-binary($file) ) then
         (: TODO: Decode the binary... :)
         t:error('INSERT102', 'XML file is a binary node, please report this to the mailing list')
      else
         t:error('INSERT003', 'XML file is neither parsed nor a document node with an element, please report this to the mailing list')
   else
      t:error('INSERT004', 'Format not known: "' || $format || '"')
};

v:console-page('../', 'tools', 'Tools', local:page#0)
