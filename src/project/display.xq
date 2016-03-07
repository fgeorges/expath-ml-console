xquery version "3.0";

import module namespace proj = "http://expath.org/ns/ml/console/project" at "proj-lib.xql";
import module namespace t    = "http://expath.org/ns/ml/console/tools"   at "../lib/tools.xql";
import module namespace v    = "http://expath.org/ns/ml/console/view"    at "../lib/view.xql";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare namespace mlc  = "http://expath.org/ns/ml/console";
declare namespace xp   = "http://expath.org/ns/project";
declare namespace xdmp = "http://marklogic.com/xdmp";

declare function local:display-file($text as text())
   as element()+
{
   <hr/>,
   <div class="md-content"> {
      $text
   }
   </div>
};

declare function local:page() as element()+
{
   let $id   := t:mandatory-field('id')
   let $proj := proj:get-descriptor($id)
   return
      if ( fn:empty($proj) ) then (
         <p>No such project, with ID <code>{ $id }</code>.</p>
      )
      else (
         <p>Project { v:proj-link($id, $id) } - { xs:string($proj/xp:title) }.</p>,
         <ul>
            <li><a href="{ $id }/src">Sources</a></li>
            <li><a href="{ $id }/checkup">Check up</a></li>
         </ul>,
         proj:get-readme($id) ! local:display-file(.)
      )
};

v:console-page('../', 'project', 'Project', local:page#0,
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
