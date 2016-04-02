xquery version "3.0";

import module namespace proj = "http://expath.org/ns/ml/console/project" at "proj-lib.xql";
import module namespace a    = "http://expath.org/ns/ml/console/admin"   at "../lib/admin.xql";
import module namespace t    = "http://expath.org/ns/ml/console/tools"   at "../lib/tools.xql";
import module namespace v    = "http://expath.org/ns/ml/console/view"    at "../lib/view.xql";

declare namespace xp = "http://expath.org/ns/project";

declare function local:page(
   $id      as xs:string?,
   $dir     as xs:string,
   $name    as xs:string,
   $abbrev  as xs:string,
   $version as xs:string,
   $title   as xs:string
) as element()+
{
   let $d := a:get-directory($dir)
   return
      if ( fn:exists($d) ) then
         <p xmlns="http://www.w3.org/1999/xhtml">
            <b>Error</b>: Project directory does exist already: <code>{ $dir }</code>.
         </p>
      else
         let $id   := ( $id, $abbrev )[1]
         let $_    := proj:add-config($id, $dir)
         let $_    := t:ensure-dir($dir || 'src/')
         let $proj := a:insert-into-directory(
                         $dir,
                         'xproject/project.xml',
                         <project xmlns="http://expath.org/ns/project"
                                  name="{ $name }"
                                  abbrev="{ $abbrev }"
                                  version="{ $version }">
                            <title>{ $title }</title>
                         </project>,
                         'indent')
         return
            <div xmlns="http://www.w3.org/1999/xhtml">
               <p>Successfuly created project { v:proj-link('../../project/' || $id, $id) }.</p>
               <ul>
                  <li>ID - <code>{ $id }</code></li>
                  <li>Directory - <code>{ $dir }</code></li>
                  <li>Project file - <code>{ $proj }</code></li>
                  <li>Name - <code>{ $name }</code></li>
                  <li>Abbrev - <code>{ $abbrev }</code></li>
                  <li>Version - <code>{ $version }</code></li>
                  <li>Title - { $title }</li>
               </ul>
            </div>/*
};

v:console-page(
   '../../',
   'project',
   'Project',
   function() {
      let $id      := t:optional-field('id', ())
      let $dir     := t:mandatory-field('dir')
      let $name    := t:mandatory-field('name')
      let $abbrev  := t:mandatory-field('abbrev')
      let $version := t:mandatory-field('version')
      let $title   := t:mandatory-field('title')
      let $dir := $dir || '/'[fn:not(fn:ends-with($dir, '/'))]
      return
         local:page($id, $dir, $name, $abbrev, $version, $title)
   })
