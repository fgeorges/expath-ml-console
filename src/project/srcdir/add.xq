xquery version "3.0";

import module namespace proj = "http://expath.org/ns/ml/console/project" at "../proj-lib.xql";
import module namespace a    = "http://expath.org/ns/ml/console/admin"   at "../../lib/admin.xql";
import module namespace t    = "http://expath.org/ns/ml/console/tools"   at "../../lib/tools.xql";
import module namespace v    = "http://expath.org/ns/ml/console/view"    at "../../lib/view.xql";

declare namespace xp = "http://expath.org/ns/project";

declare function local:page($id as xs:string, $title as xs:string, $dir as xs:string)
   as element()+
{
   if ( fn:empty(a:get-directory($dir)) ) then (
      <p xmlns="http://www.w3.org/1999/xhtml">
         <b>Error</b>: Project directory does not exist: <code>{ $dir }</code>.
      </p>
   )
   else (
      proj:add-config($id, 'srcdir', (
         proj:config-value('title', $title),
         proj:config-value('dir',   $dir))),
      local:success($id, $dir)
   )
};

declare function local:success($id  as xs:string, $dir as xs:string) as element()+
{
   <div xmlns="http://www.w3.org/1999/xhtml">
      <p>Successfuly added project { v:proj-link('../../project/' || $id, $id) }.</p>
      <ul>
         <li>ID - <code>{ $id }</code></li>
         <li>Directory - <code>{ $dir }</code></li>
      </ul>
   </div>/*
};

v:console-page(
   '../../',
   'project',
   'Project',
   function() {
      let $id    := t:mandatory-field('id')
      let $title := t:optional-field('title', ())
      let $dir   := t:mandatory-field('dir')
      let $dir   := $dir || '/'[fn:not(fn:ends-with($dir, '/'))]
      return
         local:page($id, $title, $dir)
   })
