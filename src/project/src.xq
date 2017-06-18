xquery version "3.0";

import module namespace jsp  = "http://expath.org/ns/ml/console/parser/js"
   at "parser/js-parser-lib.xql";
import module namespace xqp  = "http://expath.org/ns/ml/console/parser/xquery"
   at "parser/xquery-parser-lib.xql";

import module namespace proj   = "http://expath.org/ns/ml/console/project"        at "proj-lib.xqy";
import module namespace global = "http://expath.org/ns/ml/console/project/global" at "global-lib.xql";

import module namespace a    = "http://expath.org/ns/ml/console/admin"   at "../lib/admin.xqy";
import module namespace t    = "http://expath.org/ns/ml/console/tools"   at "../lib/tools.xqy";
import module namespace v    = "http://expath.org/ns/ml/console/view"    at "../lib/view.xql";

declare namespace mlc  = "http://expath.org/ns/ml/console";
declare namespace xdmp = "http://marklogic.com/xdmp";

declare function local:page($id as xs:string, $src as xs:string, $root as xs:string)
   as element()+
{
   <div xmlns="http://www.w3.org/1999/xhtml">
      <p>Source file <code>{ $src }</code>.</p>
      <p>In { v:proj-link($root || $id, $id) },
         in <a href="{ $root }{ $id }/src">sources</a>.</p>
      {
         let $proj := proj:project($id)
         let $lang := global:source-lang($proj, $src)
         return
            switch ( $lang )
               case 'xquery' return
                  xdmp:xslt-invoke('xsl/xquery-module-to-html.xsl',
                     xqp:parse($src, global:source($proj, $src)))
               case 'javascript' return
                  xdmp:xslt-invoke('xsl/js-module-to-html.xsl',
                     jsp:parse($src, global:source($proj, $src)))
               default return
                  <p>Language not supported: <code>{ $lang }</code>.</p>
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
             var md = marked(elem.text());
             elem.html(md);
          }});
          // TODO: Select nodes with class `md-content` AND `todo`...
          $('div.todo p:first').prepend('<code class="todo">TODO</code> ');
       </script>))
