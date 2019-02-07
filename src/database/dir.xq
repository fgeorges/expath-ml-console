xquery version "3.0";

import module namespace b   = "http://expath.org/ns/ml/console/browse"          at "browse-lib.xqy";
import module namespace dbc = "http://expath.org/ns/ml/console/database/config" at "db-config-lib.xqy";

import module namespace a = "http://expath.org/ns/ml/console/admin" at "../lib/admin.xqy";
import module namespace t = "http://expath.org/ns/ml/console/tools" at "../lib/tools.xqy";
import module namespace v = "http://expath.org/ns/ml/console/view"  at "../lib/view.xqy";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare namespace c   = "http://expath.org/ns/ml/console";
declare namespace h   = "http://www.w3.org/1999/xhtml";
declare namespace cts = "http://marklogic.com/cts";

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
   $db      as element(a:database),
   $uri     as xs:string,
   $iscoll  as xs:boolean,
   $start   as xs:integer,
   $schemes as element(c:scheme)+
) as element()+
{
   let $resolved := b:resolve-path($uri, $iscoll, $schemes)
   let $root     := xs:string($resolved/@root)
   let $sep      := xs:string($resolved/@sep)
   let $back-url := 'dir?uri=' || fn:encode-for-uri($uri)
   return (
      <p>
         { xs:string($db/a:name) ! v:db-link('../' || ., .) }
         { ' ' }
         { v:component-link(t:when($iscoll, 'croots', 'roots'), '[roots]', 'dir') }
         { ' ' }
         {
            if ( fn:exists($root) ) then
               b:uplinks($uri, $root, $sep, fn:true(), $iscoll)
            else
               t:error('invalid-uri', 'URI not configured, cannot be a dir: ' || $uri)
         }
      </p>,
      t:unless($iscoll,
         b:create-doc-form('../../', $db/a:name, $uri)),
      b:display-list(
         $uri,
         if ( $iscoll ) then
            b:get-children-coll($uri, $sep, $start)
         else
            b:get-children-uri($uri, $sep, $start),
         t:when($iscoll, 'cdir', 'dir'),
         $start,
         function($child as xs:string, $pos as xs:integer) {
            if ( $iscoll ) then
               local:coll-item($child, $sep)
            else
               local:dir-item($uri, $child, $pos, $sep)
         },
         function($items as element(h:li)+) {
            if ( fn:exists($items) ) then (
               t:when($iscoll,
                  <ul>{ $items }</ul>,
                  b:dir-children($items, $back-url))
            )
            else (
               <p>The directory is empty.</p>
            )
         }),
      (: TODO: Factorize it out in a library, support other filenames, etc. :)
      let $readme := fn:doc($uri || 'README.md')
      return
         if ( $readme/node() instance of text() ) then (
            <hr/>,
            <div class="md-content">{ $readme }</div>
         )
         else if ( fn:exists($readme) ) then (
            <hr/>,
            <div class="md-content">
               The directory contains a README file, but it is not a text document.
            </div>
         )
         else (
         )
   )
};

(:~
 : Format one directory, in case of directory browsing (as opposed to collections).
 :)
declare function local:dir-item(
   $path  as xs:string,
   $child as xs:string,
   $pos   as xs:integer,
   $sep   as xs:string
) as element()+
{
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
};

(:~
 : Format one directory, in case of collection browsing.
 :)
declare function local:coll-item(
   $child as xs:string,
   $sep   as xs:string
) as element()+
{
   if ( fn:ends-with($child, $sep) ) then (
      (: display as a "dir" :)
      <li>{ v:cdir-link('', $child, $sep) }</li>,
      (: and maybe as a "final collection" too :)
      t:when(fn:exists(cts:collection-match($child)),
         <li>{ v:coll-link('', $child, $sep) }</li>)
   )
   (: if not it is a "final collection" :)
   else (
      <li>{ v:coll-link('', $child, $sep) } </li>
   )
};

let $name    := t:mandatory-field('name')
let $type    := t:mandatory-field('type')
let $iscoll  := b:param-iscoll($type)
let $uri     := t:mandatory-field('uri')
let $prefix  := t:optional-field('prefix', ())
let $start   := xs:integer(t:optional-field('start', 1)[.])
let $lexicon := t:when($iscoll, v:ensure-coll-lexicon#2, v:ensure-uri-lexicon#2)
return
   v:console-page(
      '../../',
      'db',
      t:when($iscoll,
         'Browse collections',
         'Browse documents'),
      function() {
         v:ensure-db($name, function($db) {
            let $schemes := dbc:config-uri-schemes($db)
            let $uri     := dbc:resolve($uri, $prefix, dbc:config-uri-schemes($db))
            return
               $lexicon($db, function() {
                  t:query($db, function() {
                     local:page($db, $uri, $iscoll, $start, $schemes)
                  })
               })
         })
      },
      (<lib>emlc.browser</lib>,
       <lib>marked</lib>,
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
