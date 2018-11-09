xquery version "3.0";

import module namespace proj = "http://expath.org/ns/ml/console/project" at "proj-lib.xqy";
import module namespace t    = "http://expath.org/ns/ml/console/tools"   at "../lib/tools.xqy";
import module namespace v    = "http://expath.org/ns/ml/console/view"    at "../lib/view.xqy";

import module namespace g = "http://expath.org/ns/ml/console/project/global" at "global-lib.xqy";

import module namespace dbdir    = "http://expath.org/ns/ml/console/project/dbdir/display"
   at "dbdir/display.xqy";
import module namespace srcdir   = "http://expath.org/ns/ml/console/project/srcdir/display"
   at "srcdir/display.xqy";
import module namespace xproject = "http://expath.org/ns/ml/console/project/xproject/display"
   at "xproject/display.xqy";

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

(:~
 : Returns a string that can be used as a prefix for a link to get a binary file.
 :
 : The result of this function can be use as a "prefix" (that is, you can concat
 : a file path at the end of it) to build a URL.  This URL points to the right
 : binary endpoint (from the right database or from the filesystem).
 :
 : @param $proj The project.
 :
 : @param $root A relative path to the root of the webapp.
 :)
declare function local:bin-endpoint($proj as element(mlc:project), $root as xs:string) as xs:string
{
   if ( $proj/@type eq 'dbdir' ) then
      dbdir:bin-endpoint($proj, $root)
   else if ( $proj/@type eq 'srcdir' ) then
      srcdir:bin-endpoint($proj, $root)
   else if ( $proj/@type eq 'xproject' ) then
      xproject:bin-endpoint($proj, $root)
   else
      t:error('unknown', 'Unknown type of project: ' || $proj/@type)
};

let $proj := try { proj:project(t:mandatory-field('id')) } catch * { () }
return
   v:console-page('../', 'project', 'Project',
      function () {
         let $id   := t:mandatory-field('id')
         let $proj := proj:project($id)
         let $read := g:readme($proj)
         return
            local:page($id, $proj, $read)
      },
      if ( fn:exists($proj) ) then (
         <lib>marked</lib>,
         <script type="text/javascript">
            var renderer = new marked.Renderer();
            renderer.image = function(href, title, text) {{
               return '<img src="{ local:bin-endpoint($proj, '../') }' + href + '"></img>';
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
         </script>
      )
      else (
      ))
