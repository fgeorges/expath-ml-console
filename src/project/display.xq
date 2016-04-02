xquery version "3.0";

import module namespace proj = "http://expath.org/ns/ml/console/project" at "proj-lib.xql";
import module namespace t    = "http://expath.org/ns/ml/console/tools"   at "../lib/tools.xql";
import module namespace v    = "http://expath.org/ns/ml/console/view"    at "../lib/view.xql";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare namespace mlc  = "http://expath.org/ns/ml/console";
declare namespace xp   = "http://expath.org/ns/project";
declare namespace xdmp = "http://marklogic.com/xdmp";

declare function local:page($proj as element(mlc:project), $read as xs:string?) as element()+
{
   let $id   := xs:string($proj/@id)
   let $desc := proj:descriptor($proj)
   return
      if ( fn:empty($desc) ) then (
         <p>No such project, with ID <code>{ $id }</code>.</p>
      )
      else (
         <p>{ v:proj-link($id, $id) } - { xs:string($desc/xp:title) }.</p>,
         <ul>
            <li><a href="{ $id }/src">Sources</a></li>
            <li><a href="{ $id }/checkup">Check up</a></li>
         </ul>,
         <hr/>,
         <div class="md-content"> {
            t:default(
               $read,
               'Create a `README.md` file in the project directory to be displayed here.')
         }
         </div>
      )
};

let $id   := t:mandatory-field('id')
let $proj := proj:project($id)
let $read := proj:readme($proj)
return
   v:console-page('../', 'project', t:exists($read, '', 'Project'),
      function () {
         local:page($proj, $read)
      },
      (v:import-javascript('../js/', ('marked.min.js', 'highlight/highlight.pack.js')),
       <script type="text/javascript">
          marked.setOptions({{
             highlight: function (code) {{
                return hljs.highlightAuto(code).value;
             }}
          }});
          $('.md-content').each(function() {{
             var elem = $(this);
             elem.html(marked(elem.text()));
          }});
       </script>))
