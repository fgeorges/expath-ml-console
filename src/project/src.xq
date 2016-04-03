xquery version "3.0";

import module namespace proj = "http://expath.org/ns/ml/console/project" at "proj-lib.xql";
import module namespace xqp  = "http://expath.org/ns/ml/console/parser/xquery"
   at "xquery-parser-lib.xql";
import module namespace a    = "http://expath.org/ns/ml/console/admin"   at "../lib/admin.xql";
import module namespace t    = "http://expath.org/ns/ml/console/tools"   at "../lib/tools.xql";
import module namespace v    = "http://expath.org/ns/ml/console/view"    at "../lib/view.xql";

import module namespace srcdir   = "http://expath.org/ns/ml/console/project/srcdir"   at "srcdir-lib.xql";
import module namespace xproject = "http://expath.org/ns/ml/console/project/xproject" at "xproject-lib.xql";

declare namespace mlc  = "http://expath.org/ns/ml/console";
declare namespace xdmp = "http://marklogic.com/xdmp";

declare function local:source($proj as element(mlc:project), $src as xs:string) as text()?
{
   if ( $proj/@type eq 'srcdir' ) then
      srcdir:source($proj, $src)
   else if ( $proj/@type eq 'xproject' ) then
      xproject:source($proj, $src)
   else
      t:error('unknown', 'Unknown type of project: ' || $proj/@type)
};

declare function local:page($id as xs:string, $src as xs:string, $root as xs:string)
   as element()+
{
   <div xmlns="http://www.w3.org/1999/xhtml">
      <p>Source file <code>{ $src }</code>.</p>
      <p>In { v:proj-link($root || $id, $id) },
         in <a href="{ $root }{ $id }/src">sources</a>.</p>
      {
         let $mod := xqp:parse($src, proj:project($id) ! local:source(., $src))
         return
            xdmp:xslt-invoke('xsl/module-to-html.xsl', $mod)
      }
   </div>/*
};

let $id   := t:mandatory-field('id')
let $src  := t:mandatory-field('src')
let $toks := fn:tokenize($src, '/')
let $root := t:make-string('../', fn:count($toks) + 1)
return
   v:console-page(
      $root || '../../',
      'project',
      $toks[fn:last()],
      function() { local:page($id, $src, $root) },
      (v:import-javascript($root || '../../js/', (
          'marked.min.js',
          'highlight/highlight.pack.js')),
       <script type="text/javascript" xmlns="http://www.w3.org/1999/xhtml">
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
