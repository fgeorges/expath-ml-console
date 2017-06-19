xquery version "3.0";

import module namespace proj = "http://expath.org/ns/ml/console/project" at "../proj-lib.xqy";
import module namespace a    = "http://expath.org/ns/ml/console/admin"   at "../../lib/admin.xqy";
import module namespace t    = "http://expath.org/ns/ml/console/tools"   at "../../lib/tools.xqy";
import module namespace v    = "http://expath.org/ns/ml/console/view"    at "../../lib/view.xqy";

declare namespace err   = "http://www.w3.org/2005/xqt-errors";
declare namespace error = "http://marklogic.com/xdmp/error";
declare namespace xp    = "http://expath.org/ns/project";

declare function local:do-create(
   $id      as xs:string?,
   $dir     as xs:string,
   $name    as xs:string,
   $abbrev  as xs:string,
   $version as xs:string,
   $title   as xs:string
) as element()+
{
   let $id   := ( $id, $abbrev )[1]
   let $_    := proj:add-config($id, 'xproject', proj:config-value('dir', $dir))
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
         <p>Successfuly created project { v:proj-link('../../' || $id, $id) }.</p>
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

(: TODO: To be in a proper library for tools for handling ML errors... :)
declare function local:is-dir-perm-denied($err as element(error:error)) as xs:boolean
{
   $err/error:code eq 'SVC-DIRCREAT'
      and ( every $d in ('mkdir', 'Permission denied') satisfies $err/error:data/error:datum = $d )
};

declare function local:page(
   $id      as xs:string?,
   $dir     as xs:string,
   $name    as xs:string,
   $abbrev  as xs:string,
   $version as xs:string,
   $title   as xs:string
) as element()+
{
   if ( fn:exists(a:get-directory($dir)) ) then
      <p xmlns="http://www.w3.org/1999/xhtml">
         <b>Error</b>: Project directory does exist already: <code>{ $dir }</code>.
      </p>
   else
      try {
         local:do-create($id, $dir, $name, $abbrev, $version, $title)
      }
      catch err:FOER0000 {
         if ( local:is-dir-perm-denied($err:additional) ) then
            <div xmlns="http://www.w3.org/1999/xhtml">
               <p>Permission denied to create the directory
                  <code>{ $err:additional/error:data/error:datum[2]/xs:string(.) }</code>.</p>
               <p>Make sure that the user running MarkLogic Server has the right to create
                  files and directories in the parent directory.</p>
            </div>/*
         else
            fn:error(xs:QName('err:FOER0000'), $err:description, $err:additional)
      }
};

v:console-page(
   '../../../',
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
