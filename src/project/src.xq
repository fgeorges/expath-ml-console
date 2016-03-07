xquery version "3.0";

import module namespace proj = "http://expath.org/ns/ml/console/project" at "proj-lib.xql";
import module namespace xqp  = "http://expath.org/ns/ml/console/parser/xquery"
   at "xquery-parser-lib.xql";
import module namespace a    = "http://expath.org/ns/ml/console/admin"   at "../lib/admin.xql";
import module namespace t    = "http://expath.org/ns/ml/console/tools"   at "../lib/tools.xql";
import module namespace v    = "http://expath.org/ns/ml/console/view"    at "../lib/view.xql";

declare namespace xdmp = "http://marklogic.com/xdmp";

declare function local:page($id as xs:string, $src as xs:string, $root as xs:string)
   as element()+
{
   <div xmlns="http://www.w3.org/1999/xhtml">
      <p>Source file <code>{ $src }</code>.</p>
      <p>In { v:proj-link($root || $id, $id) },
         in <a href="{ $root }{ $id }/src">sources</a>.</p>
      {
(: DEBUG: Plug one of the Console source file instead of the actual $src... :)
(:
         let $file := (
                  'lib/admin.xql',
                  'lib/tools.xql',
                  'project/xquery-parser-lib.xql'
               )[3]
         let $mod := xqp:parse(
                        $file,
                        a:get-from-directory(
                           '/Users/fgeorges/projects/expath/ml-console/src/',
                           $file,
                           fn:false()))
:)
         let $mod := xqp:parse($src, proj:get-source($id, $src))
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
