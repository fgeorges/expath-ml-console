xquery version "3.0";

import module namespace dbc = "http://expath.org/ns/ml/console/database/config" at "../database/db-config-lib.xqy";

import module namespace a   = "http://expath.org/ns/ml/console/admin"  at "../lib/admin.xqy";
import module namespace bin = "http://expath.org/ns/ml/console/binary" at "../lib/binary.xqy";
import module namespace t   = "http://expath.org/ns/ml/console/tools"  at "../lib/tools.xqy";
import module namespace v   = "http://expath.org/ns/ml/console/view"   at "../lib/view.xqy";

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
      else if ( $ext = ('md') ) then (
         <hr/>,
         <div class="md-content"> {
            a:get-from-filesystem($uri)
         }
         </div>,
         <div id="footpane">
            <div id="footline">
               <span>▼</span>
               <span>Result</span>
               <span>▲</span>
            </div>
            <div id="footbody">
               <pre><code>[no result to display, yet]</code></pre>
            </div>
         </div>,
         <div style="display: none" id="emlc-db-widget-template">
            <!-- does not bear the "emlc-target-widget" class, must be added when cloning -->
            <div class="row" style="margin-bottom: 20px; margin-left: 0;"> {
               let $dbs   := a:get-databases()/a:database
               let $asses := a:get-appservers()/a:appserver
               return (
                  local:db-button('Database', $dbs),
                  local:as-button('HTTP',   $asses[@type eq 'http']),
                  local:as-button('XDBC',   $asses[@type eq 'xdbc']),
                  local:as-button('ODBC',   $asses[@type eq 'odbc']),
                  local:as-button('WebDAV', $asses[@type eq 'webDAV']),
                  <div class="col">
                     <button type="button" class="emlc-target-execute btn btn-outline-secondary float-right">
                        Execute
                     </button>
                  </div>
               )
            }
            </div>
         </div>
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

declare function local:button(
   $label  as xs:string,
   $values as element(a)+
) as element(div)
{
   <div class="emlc-target-selector btn-group" style="margin-right: 15px;" data-label="{ $label }">
      <button type="button" class="btn btn-outline-secondary dropdown-toggle"
              data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">
         { $label }
      </button>
      <div class="dropdown-menu" style="min-width: 400pt">
         { $values }
      </div>
   </div>
};

declare function local:db-button(
   $label as xs:string,
   $dbs   as element(a:database)+)
{
   local:button(
      $label,
      for $db in $dbs
      order by $db/a:name
      return
         v:format-db-widget-db($db))
};

declare function local:as-button($label as xs:string, $asses as element(a:appserver)*)
{
   if ( fn:exists($asses) ) then
      local:button(
         $label,
         for $as in $asses
         order by $as/a:name
         return
            v:format-db-widget-as($as, $label))
   else
      ()
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
      (<lib>emlc.browser</lib>,
       (: TODO: These 3 are necessary only in case we actually generate the
          executable MarkDown snippets.  Or at least if we do have an MD file,
          which we can detect here.  The emlc.markdown code can then display the
          entire footpane only if it does generate such snippets. :)
       <lib>emlc.footpane</lib>,
       <lib>emlc.markdown</lib>,
       <lib>emlc.target</lib>,
       (: /todo :)
       <script>
          emlc.renderMarkdown('./', '{ $uri }');
       </script>))
