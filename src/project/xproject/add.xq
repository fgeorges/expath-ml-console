xquery version "3.0";

import module namespace proj = "http://expath.org/ns/ml/console/project" at "../proj-lib.xql";
import module namespace a    = "http://expath.org/ns/ml/console/admin"   at "../../lib/admin.xql";
import module namespace t    = "http://expath.org/ns/ml/console/tools"   at "../../lib/tools.xql";
import module namespace v    = "http://expath.org/ns/ml/console/view"    at "../../lib/view.xql";

declare namespace xp = "http://expath.org/ns/project";

declare function local:page($id as xs:string?, $dir as xs:string)
   as element()+
{
   let $d := a:get-directory($dir)
   return
      if ( fn:empty($d) ) then
         <p xmlns="http://www.w3.org/1999/xhtml">
            <b>Error</b>: Project directory does not exist: <code>{ $dir }</code>.
         </p>
      else
         let $proj := a:get-from-directory($dir, 'xproject/project.xml', fn:true())/*
         let $id   := if ( fn:exists($id) ) then $id else $proj/@abbrev
         return
            if ( fn:empty($proj) ) then (
               <p xmlns="http://www.w3.org/1999/xhtml">
                  <b>Error</b>: Project file does not exist: <code>{ $dir }xproject/project.xml</code>.
               </p>
            )
            else (
               proj:add-config($id, 'xproject', proj:config-value('dir', $dir)),
               local:success($id, $dir, $proj)
            )
};

declare function local:success(
   $id   as xs:string,
   $dir  as xs:string,
   $proj as element(xp:project)
) as element()+
{
   <div xmlns="http://www.w3.org/1999/xhtml">
      <p>Successfuly added project { v:proj-link('../../project/' || $id, $id) }.</p>
      <ul>
         <li>ID - <code>{ $id }</code></li>
         <li>Directory - <code>{ $dir }</code></li>
         <li>Name - <code>{ $proj/xs:string(@name) }</code></li>
         <li>Abbrev - <code>{ $proj/xs:string(@abbrev) }</code></li>
         <li>Version - <code>{ $proj/xs:string(@version) }</code></li>
         <li>Title - { $proj/xs:string(xp:title) }</li>
      </ul>
   </div>/*
};

v:console-page(
   '../../',
   'project',
   'Project',
   function() {
      let $id  := t:optional-field('id', ())
      let $dir := t:mandatory-field('dir')
      let $dir := $dir || '/'[fn:not(fn:ends-with($dir, '/'))]
      return
         local:page($id, $dir)
   })
