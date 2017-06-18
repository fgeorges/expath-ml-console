xquery version "3.0";

import module namespace parser = "http://github.com/jpcs/xqueryparser.xq"
   at "parser/xqueryparser.xq";
import module namespace p = "XQueryML30"
   at "parser/lib/XQueryML30.xq";
import module namespace xqd = "http://github.com/xquery/xquerydoc"
   at "xquerydoc/src/xquery/xquerydoc.xq";
import module namespace xqdc = "XQDocComments"
   at "xquerydoc/src/xquery/parsers/XQDocComments.xq";

import module namespace proj = "http://expath.org/ns/ml/console/project" at "proj-lib.xqy";
import module namespace a    = "http://expath.org/ns/ml/console/admin"   at "../lib/admin.xqy";
import module namespace v    = "http://expath.org/ns/ml/console/view"    at "../lib/view.xql";

declare namespace xdmp = "http://marklogic.com/xdmp";

declare function local:parse($module as xs:string) as node()*
{
   let $ast := parser:parse($module)
   return
      $ast/Module/MainModule
};

declare function local:page() as element()+
{
   <div xmlns="http://www.w3.org/1999/xhtml"> {
   <p>Module:</p>,
   <pre> {
      proj:project('hello-world') ! proj:source(., 'hello.xq')
   }
   </pre>,
   <p>xqdc:parse-Comments fails this one:</p>,
   <pre> {
      xdmp:quote(
         xqdc:parse-Comments(
'(:~
 : Private helper for `t:parse-content-type-1()`.
 :
 : separators     = "(" | ")" | "&amp;lt;" | "&gt;" | "_"
 :                | "," | ";" | ":" | "\" | &amp;lt;"&gt;
 :                | "/" | "[" | "]" | "?" | "="
 :                | "{" | "}" | SP | HT
 : 
 : The problem is because:
 : 
 : - the above text contains _lt;
 : - the above text contains [the AT sign]
 :) '))
   }
   </pre>,
   <p>hello.xq:</p>,
   <pre> {
      xdmp:quote(
         parser:parse(
            a:get-from-directory(
               '/Users/fgeorges/projects/expath/ml-console/test/hello-world/src/',
               'hello.xq',
               fn:false())))
   }
   </pre>,
   <p>yet-another-hello.xql:</p>,
   <pre> {
      xdmp:quote(
         parser:parse(
            a:get-from-directory(
               '/Users/fgeorges/projects/expath/ml-console/test/hello-world/src/foo/bar/',
               'yet-another-hello.xql',
               fn:false())))
   }
   </pre>,
   <p>Parser:</p>,
   <pre> {
      xdmp:quote(
         parser:parse(
            a:get-from-directory(
               '/Users/fgeorges/projects/expath/ml-console/src/lib/',
               'tools.xql',
               fn:false())))
   }
   </pre>,
   <p>Attempt:</p>,
   <pre> {
      xdmp:quote(
         local:parse(
            proj:project('hello-world') ! proj:source(., 'hello.xq')))
   }
   </pre>,
   <p>Parser:</p>,
   <pre> {
      xdmp:quote(
         parser:parse(
            proj:project('hello-world') ! proj:source(., 'hello.xq')))
   }
   </pre>,
   <p>Original parser:</p>,
   <pre> {
      xdmp:quote(
         p:parse-XQuery(
            proj:project('hello-world') ! proj:source(., 'hello.xq')))
   }
   </pre>,
   <p>XQD parser:</p>,
   <pre> {
      xdmp:quote(
         xqd:parse(
            proj:project('hello-world') ! proj:source(., 'hello.xq')))
   }
   </pre>,
   <p>XQD parser, simpler case:</p>,
   <pre> {
      xdmp:quote(
         xqd:parse('xquery version "1.0";

module namespace h = "http://example.org/hello";

(:~
 : Say hello.
 :
 : @param $who Who to say hello to.
 :)
declare function h:greetings($who as xs:string)
{
   fn:concat("Hello, ", $who, "!")
};
'))
   }
   </pre>,
   <p>Text before, with some <code>code</code>.</p>,
   <div class="md-content">
## Marked in browser

Rendered by **marked**.

The initialization code:

```js
marked.setOptions({{
   highlight: function (code) {{
      return hljs.highlightAuto(code).value;
   }}
}});
$('.md-content').each(function() {{
   var elem = $(this);
   elem.html(marked(elem.text()));
}});
```

## Bouia

Et maintenant de l'XQuery :

```xquery
xquery version "3.0";

import module namespace v = "http://expath.org/ns/ml/console/view"  at "../lib/view.xql";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare function local:page() as element()+
{{
   &lt;p>Text before, with some &lt;code>code&lt;/code>.&lt;/p>
}}
```

## Links

Text with a [link](foobar) to `foobar`.  Another [one](foobar/) to `foobar/`.
And to [file.md](file.md) and to [dir/file.md](dir/file.md).
   </div>,
   let $as   := a:get-appserver-by-name('expath-console')
   let $path := $as/a:modules-path  || '../README.md'
   return
      local:display-file('EXPath Console', $path),
   local:display-file('ML Book', '/Users/fgeorges/projects/ml/ml-book/README.md'),
   local:display-file('ML Blog', '/Users/fgeorges/projects/ml/ml-book/blog/README.md')
   }
   </div>
};

declare function local:display-file($title as xs:string, $path as xs:string)
   as element()+
{
   <div xmlns="http://www.w3.org/1999/xhtml"> {
   <hr/>,
   <h1>{ $title }</h1>,
   <hr/>,
   <div class="md-content"> {
      xdmp:document-get(
         $path,
         <options xmlns="xdmp:document-get">
            <format>text</format>
         </options>)
   }
   </div>
   }
   </div>
};

v:console-page('../', 'project', 'Projects', local:page#0,
   (v:import-javascript('../js/', ('marked.min.js', 'highlight/highlight.pack.js')),
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
