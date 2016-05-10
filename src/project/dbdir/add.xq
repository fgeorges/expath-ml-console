xquery version "3.0";

import module namespace proj = "http://expath.org/ns/ml/console/project" at "../proj-lib.xql";
import module namespace a    = "http://expath.org/ns/ml/console/admin"   at "../../lib/admin.xql";
import module namespace t    = "http://expath.org/ns/ml/console/tools"   at "../../lib/tools.xql";
import module namespace v    = "http://expath.org/ns/ml/console/view"    at "../../lib/view.xql";

declare namespace xp = "http://expath.org/ns/project";

declare function local:page($id as xs:string, $title as xs:string, $db as xs:string, $root as xs:string)
   as element()+
{
   proj:add-config($id, 'dbdir', (
      proj:config-key-value('title', $title),
      proj:config-key-value('db',    $db),
      proj:config-key-value('root',  $root))),
   local:success($id, $db, $root)
};

declare function local:success($id as xs:string, $db as xs:string, $root as xs:string) as element()+
{
   <div xmlns="http://www.w3.org/1999/xhtml">
      <p>Successfuly added project { v:proj-link('../../project/' || $id, $id) }.</p>
      <ul>
         <li>ID - <code>{ $id }</code></li>
         <li>Database - <code>{ $db }</code></li>
         <li>Root - <code>{ $root }</code></li>
      </ul>
   </div>/*
};

v:console-page(
   '../../',
   'project',
   'Project',
   function() {
      let $db    := t:mandatory-field('database')
      let $id    := t:mandatory-field('id')
      let $title := t:optional-field('title', ())
      let $root  := t:optional-field('root', ())
      let $root  := $root || '/'[$root][fn:not(fn:ends-with($root, '/'))]
      return
         local:page($id, $title, $db, $root)
   })
