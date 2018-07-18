xquery version "3.0";

import module namespace b = "http://expath.org/ns/ml/console/browse" at "../database/browse-lib.xqy";

import module namespace a = "http://expath.org/ns/ml/console/admin" at "../lib/admin.xqy";
import module namespace t = "http://expath.org/ns/ml/console/tools" at "../lib/tools.xqy";
import module namespace v = "http://expath.org/ns/ml/console/view"  at "../lib/view.xqy";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare namespace dir = "http://marklogic.com/xdmp/directory";
declare namespace h   = "http://www.w3.org/1999/xhtml";

(:~
 : The overall page function.
 : 
 : TODO: Display whether the directory exists per se in MarkLogic (and its
 : properties if it has any, etc.)
 :
 : TODO: Is there a way to detect whether there is a URI Privilege for a specific
 : directory?  A way to say "the creation of documents in this directory is
 : protected by privilege xyz..."
 :
 : TODO: Document... (especially the fact it accesses the entire URI index,
 : should be a problem with large databases, with a shit loads of documents.
 :
 : TODO: The details of how to retrieve the children must be in lib/admin.xqy.
 :
 : TODO: Lot of duplicated code with local:page() in roots.xq, factorize out?
 :)
declare function local:page(
   $uri   as xs:string,
   $start as xs:integer
) as element()+
{
   let $dir := a:get-directory($uri)
   return (
      <p>
         { v:component-link('roots', '[roots]', 'dir') }
         { ' ' }
         { local:uplinks($uri) }
      </p>,
      if ( fn:exists($dir) ) then (
         (:TODO: Create form not supported yet on FS... :)
         (: b:create-doc-form('../../', $db/a:name, $uri), :)
         b:display-list(
            $uri,
            local:get-children($uri, $start),
            'dir',
            $start,
            function($child as xs:string, $pos as xs:integer) {
               local:item($uri, $child, $pos)
            },
            function($items as element(h:li)+) {
               if ( fn:exists($items) ) then (
                  <ul>{ $items }</ul>
                  (: TODO: Does not support delete form for FS yet... :)
                  (: b:dir-children($items, $back-url) :)
               )
               else (
                  <p>The directory is empty.</p>
               )
            }),
         let $readme := a:get-from-filesystem($uri || 'README.md')
         return
            if ( fn:exists($readme) ) then (
               <hr/>,
               <div class="md-content">{ $readme }</div>
            )
            else (
            )
      )
      else (
         (: TODO: Propose to create it? :)
         <p>The directory does not exist.</p>
      )
   )
};

(: TODO: Duplicated in doc.xq... :)
declare function local:uplinks($uri as xs:string) as node()+
{
   local:uplinks-1('', fn:tokenize($uri, '/')[fn:position() ne fn:last()])
};

(: TODO: Duplicated in doc.xq... :)
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
 : Format one item.
 :)
declare function local:get-children(
   $uri   as xs:string,
   $start as xs:integer
) as item()*
{
   (: TODO: $start not supported yet... Or is it in b:display-list anyway? :)
   a:get-directory($uri)/dir:entry
      ! ( dir:pathname || t:when(dir:type eq 'directory', '/') )
};

(:~
 : Format one item.
 :)
declare function local:item(
   $uri   as xs:string,
   $child as item(),
   $pos   as xs:integer
) as element()+
{
   (: TODO: Does not support delete form for FS yet... :)
   (:
   let $kind := if ( fn:ends-with($child, $sep) ) then 'dir' else 'doc'
   return
      <li>
         <input name="name-{ $pos }" type="hidden" value="{ $child }"/>
         <input name="delete-{ $kind }-{ $pos }" type="checkbox"/>
         { ' ' }
         {
            if ( $kind eq 'dir' ) then
               v:dir-link('', $child, $sep)
            else
               v:doc-link('', $child, $sep)
         }
      </li>
   :)
   <li> {
      if ( fn:ends-with($child, '/') ) then
         v:dir-link('', $child, '/')
      else
         v:doc-link('', $child, '/')
   }
   </li>
};

let $uri   := t:mandatory-field('uri')
let $start := xs:integer(t:optional-field('start', 1)[.])
return
   v:console-page(
      '../../',
      'project',
      'Browse file system',
      function() {
         local:page($uri, $start)
      },
      (b:create-doc-javascript(),
       v:import-javascript('../js/', ('marked.min.js', 'highlight/highlight.pack.js')),
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
