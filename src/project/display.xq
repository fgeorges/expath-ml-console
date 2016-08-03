xquery version "3.0";

import module namespace proj = "http://expath.org/ns/ml/console/project" at "proj-lib.xql";
import module namespace t    = "http://expath.org/ns/ml/console/tools"   at "../lib/tools.xql";
import module namespace v    = "http://expath.org/ns/ml/console/view"    at "../lib/view.xql";

import module namespace g = "http://expath.org/ns/ml/console/project/global" at "global-lib.xql";

import module namespace dbdir    = "http://expath.org/ns/ml/console/project/dbdir/display"
   at "dbdir/display.xql";
import module namespace srcdir   = "http://expath.org/ns/ml/console/project/srcdir/display"
   at "srcdir/display.xql";
import module namespace xproject = "http://expath.org/ns/ml/console/project/xproject/display"
   at "xproject/display.xql";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare namespace mlc  = "http://expath.org/ns/ml/console";
declare namespace xp   = "http://expath.org/ns/project";
declare namespace xdmp = "http://marklogic.com/xdmp";

declare function local:page(
   $id   as xs:string,
   $proj as element(mlc:project),
   $read as xs:string?
) as element()+
{
   if ( $proj/@type eq 'dbdir' ) then
      dbdir:page($proj)
   else if ( $proj/@type eq 'srcdir' ) then
      srcdir:page($proj)
   else if ( $proj/@type eq 'xproject' ) then
      xproject:page($id, $proj, $read)
   else
      t:error('unknown', 'Unknown type of project: ' || $proj/@type)
   ,
   <hr/>,
   <div class="md-content"> {
      t:default(
         $read,
         'Create a `README.md` file in the project directory to be displayed here.')
   }
   </div>
};

let $id   := t:mandatory-field('id')
let $proj := proj:project($id)
let $read := g:readme($proj)
return
   v:console-page('../', 'project', t:exists($read, '', 'Project'),
      function () {
         local:page($id, $proj, $read)
      },
      (v:import-javascript('../js/', ('marked.min.js', 'highlight/highlight.pack.js')),
       <script type="text/javascript">
          var renderer = new marked.Renderer();
          renderer.image = function(href, title, text) {{
             return '<img src="bin?uri={ $uri }' + href + '"></img>';
          }};
          marked.setOptions({{
             highlight: function (code) {{
                return hljs.highlightAuto(code).value;
             }},
             renderer: renderer
          }});
          $('.md-content').each(function() {{
             var elem = $(this);
             elem.html(marked(elem.text()));
          }});
       </script>))
