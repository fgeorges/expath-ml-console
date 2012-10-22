xquery version "1.0-ml"; (: 1.0-ml required for "binary()" :)

(:~
 : Insert a document or a directory into a specific database.
 :
 : Accept the following request fields for a file (all mandatory except
 : override):
 :   - database: the ID of the target database
 :   - uri: the target URI where to insert the file
 :   - file: the file itself
 :   - format: the format of the file (either 'xml', 'text' or 'binary')
 :   - override: allow overriding an existing file (false by default)
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

import module namespace a = "http://expath.org/ns/ml/console/admin" at "../lib/admin.xql";
import module namespace t = "http://expath.org/ns/ml/console/tools" at "../lib/tools.xql";
import module namespace v = "http://expath.org/ns/ml/console/view"  at "../lib/view.xql";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare namespace prop = "http://marklogic.com/xdmp/property";
declare namespace xdmp = "http://marklogic.com/xdmp";

(:~
 : Handle the case "insert a file".
 :)
declare function local:handle-file($file as node())
{
   let $db-id    := xs:unsignedLong(t:mandatory-field('database'))
   let $uri      := t:mandatory-field('uri')
   let $format   := t:mandatory-field('format')
   let $override := xs:boolean(t:optional-field('override', 'false'))
   return
      v:console-page(
         'tools',
         'Tools',
         if ( fn:doc-available($uri) and fn:not($override) ) then
            <p><b>Error</b>: File already exists at { $uri }.</p>
         else
            let $node   := local:get-node($file, $format)
            let $result := a:insert-into-database($db-id, $uri, $node)
            return
               <p>File succesfully inserted at { $result } as { $format }.</p>)
};

(:~
 : Return () if $uri does NOT exist, and an error message in case it does exist.
 :)
declare function local:dir-exists($uri as xs:string)
   as element(p)?
{
   let $props := xdmp:document-properties($uri)
   return
      if ( fn:not(fn:ends-with($uri, '/')) ) then
         <p><b>Error</b>: Directory name must end with a slash, but you provided '{ $uri }'.</p>
      else if ( fn:exists($props/prop:properties/prop:directory) ) then
         <p><b>Error</b>: Directory already exists at '{ $uri }'.</p>
      else if ( fn:exists($props) ) then
         (: this should never happen if $uri ends with a slash :)
         <p><b>Error</b>: A FILE already exists at '{ $uri }'.</p>
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
      v:console-page(
         'tools',
         'Tools',
         if ( fn:exists($exists) ) then
            $exists
         else
            let $result := a:load-dir-into-database($db-id, $uri, $dir, $include, $exclude)
            return
               <p>Directory succesfully uploaded at '{ $result }' from '{ $dir }'.</p>)
};

(:~
 : Handle the case "insert a zipped directory".
 :)
declare function local:handle-zipdir($zip as binary())
{
   let $db-id  := xs:unsignedLong(t:mandatory-field('database'))
   let $uri    := t:mandatory-field('uri')
   let $exists := local:dir-exists($uri)
   return
      v:console-page(
         'tools',
         'Tools',
         if ( fn:exists($exists) ) then
            $exists
         else
            let $result := a:load-zipdir-into-database($db-id, $uri, $zip)
            return
               <p>Directory succesfully uploaded at '{ $result }' from ZIP file.</p>)
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
declare function local:get-node($file as node(), $format as xs:string)
   as node()
{
   if ( $format eq 'text' and $file instance of document-node() and fn:exists($file/text()) ) then
      $file
   else if ( $format eq 'text' and $file instance of binary() ) then
      t:error('INSERT101', 'Text file is a binary node, please report this to the mailing list')
   else if ( $format eq 'text' ) then
      t:error('INSERT001', 'Text file is not a text node, please report this to the mailing list')
   else if ( $format eq 'binary' and $file instance of binary() ) then
      $file
   else if ( $format eq 'binary' ) then
      t:error('INSERT002', 'Binary file is not a binary node, please report this to the mailing list')
   else if ( $format eq 'xml' and $file instance of document-node() and fn:exists($file/*) ) then
      $file
   else if ( $format eq 'xml' and $file instance of document-node() and fn:exists($file/text()) ) then
      xdmp:unquote($file)
   else if ( $format eq 'xml' and $file instance of binary() ) then
      t:error('INSERT102', 'XML file is a binary node, please report this to the mailing list')
   else if ( $format eq 'xml' ) then
      t:error('INSERT003', 'XML file is neither parsed nor a document node with an element, please report this to the mailing list')
   else
      t:error('INSERT004', fn:concat('Format not known: "', $format, '"'))
};

(: TODO: Check the params are there, and validate them... :)
let $file   := t:optional-field('file', ())
let $dir    := t:optional-field('dir', ())
let $zipdir := t:optional-field('zipdir', ())
let $count  := fn:count(($file, $dir, $zipdir))
return
   if ( $count ne 1 ) then
      <p><b>Error</b>: Exactly 1 parameter out of 'file', 'dir' and 'zipdir'
         should be provided. Got { $count } of them.  File is '{ $file }', dir
         is '{ $dir }' and zipdir is '{ $zipdir }'.</p>
   else if ( fn:exists($file) ) then
      local:handle-file($file)
   else if ( fn:exists($dir) ) then
      local:handle-dir($dir)
   else
      local:handle-zipdir($zipdir)
