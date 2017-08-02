xquery version "3.0";

import module namespace b   = "http://expath.org/ns/ml/console/browse"          at "../database/browse-lib.xql";
import module namespace dbc = "http://expath.org/ns/ml/console/database/config" at "../database/db-config-lib.xql";

import module namespace a   = "http://expath.org/ns/ml/console/admin"  at "../lib/admin.xqy";
import module namespace bin = "http://expath.org/ns/ml/console/binary" at "../lib/binary.xqy";
import module namespace t   = "http://expath.org/ns/ml/console/tools"  at "../lib/tools.xqy";
import module namespace v   = "http://expath.org/ns/ml/console/view"   at "../lib/view.xql";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare namespace dir  = "http://marklogic.com/xdmp/directory";
declare namespace c    = "http://expath.org/ns/ml/console";
declare namespace xdmp = "http://marklogic.com/xdmp";
declare namespace sec  = "http://marklogic.com/xdmp/security";

(:~
 : The overall page function.
 :)
declare function local:page($uri as xs:string)
   as element()+
{
   let $paths    := fn:tokenize($uri, '/')
   let $basename := $paths[fn:last()]
   let $dirname  := fn:string-join($paths[fn:position() ne fn:last()], '/') || '/'
   let $dir      := a:get-directory($dirname)
   let $file     := $dir/dir:entry[dir:filename eq $basename]
   return (
      <p>
         { v:component-link('roots', '[roots]', 'dir') }
         { ' ' }
         { local:uplinks($uri, $paths) }
      </p>,
      if ( fn:empty($file) ) then (
         <p>The file <code>{ $uri }</code> does not exist.</p>
      )
      else (
         local:summary($uri, $file),
         local:content($uri, $file)
      )
   )
};

(: TODO: Duplicated in dir.xq... :)
declare function local:uplinks($uri as xs:string, $paths as xs:string+) as node()+
{
   local:uplinks-1('', $paths[fn:position() ne fn:last()]),
   text { ' ' },
   v:doc-link('', $uri, '/')
};

(: TODO: Duplicated in dir.xq... :)
declare function local:uplinks-1($parent as xs:string, $paths as xs:string*) as node()*
{
   if ( fn:exists($paths) ) then
      let $uri := $parent || fn:head($paths) || '/'
      return (
         text { ' ' },
         v:dir-link('', $uri, '/'),
         local:uplinks-1($uri, fn:tail($paths))
      )
   else
      ()
};

(:~
 : The summary section.
 :
 : @todo Add all infos from `$file`...
 :)
declare function local:summary($uri as xs:string, $file as element(dir:entry))
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
            <td>File URI</td>
            <td><code>{ $uri }</code></td>
         </tr>
      </tbody>
   </table>
};

(:~
 : The content section.
 :)
declare function local:content(
   $uri  as xs:string,
   $file as element(dir:entry)
) as element()+
{
   <h3>Content</h3>,
   <p>You can <a href="bin?uri={ $uri }">download</a> the document.</p>,
   let $id  := fn:generate-id($file)
   let $ext := fn:tokenize($file/dir:filename, '\.')[fn:last()]
   return
      (: TODO: See if there is a project at one of the ancestor dir, and take the
         types/extension mapping from there... :)
      (: TODO: Support more types, support edit, etc. :)
      if ( $ext = ('xml') ) then (
         v:ace-editor(a:get-from-filesystem($uri), 'code', 'xml', (), (), (), ())
      )
      else if ( $ext = ('xq', 'xql', 'xqm', 'xqy', 'xquery') ) then (
         v:ace-editor(a:get-from-filesystem($uri), 'code', 'xquery', (), (), (), ())
      )
(:
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
:)
      else (
         <p>Binary document display not supported.</p>
      )
};

let $uri := t:mandatory-field('uri')
return
   v:console-page(
      '../../',
      'project',
      'Browse file system',
      function() {
         local:page($uri)
      },
      b:create-doc-javascript())
