xquery version "3.0";

(:~
 : Project information retrieval and manipulation.
 :)
module namespace proj = "http://expath.org/ns/ml/console/project";

import module namespace a = "http://expath.org/ns/ml/console/admin" at "../lib/admin.xql";
import module namespace t = "http://expath.org/ns/ml/console/tools" at "../lib/tools.xql";

declare namespace mlc  = "http://expath.org/ns/ml/console";
declare namespace xp   = "http://expath.org/ns/project";
declare namespace xdmp = "http://marklogic.com/xdmp";

(:~
 : The Console config file URI.
 : 
 : @todo Move to a Console-global library.
 :)
declare variable $proj:config-uri := 'http://expath.org/ml/console/config.xml';

(:~
 : Return true if the Console config file exists.
 : 
 : @todo Move to a Console-global library.
 :)
declare function proj:is-console-init()
   as xs:boolean
{
   fn:doc-available($proj:config-uri)
};

(:~
 : Create the Console config file.
 : 
 : @todo Move to a Console-global library.
 :)
declare function proj:init-console()
   as empty-sequence()
{
   if ( proj:is-console-init() ) then
      t:error('already-init', 'The config file already exists')
   else
      xdmp:document-insert(
         $proj:config-uri,
         <console xmlns="http://expath.org/ns/ml/console">
            <projects/>
         </console>)
};

(:~
 : The ID of all projects.
 : 
 : @return A sequence of IDs.
 :)
declare function proj:get-project-ids()
   as xs:string*
{
   fn:doc($proj:config-uri)/mlc:console/mlc:projects/mlc:project/@id
};

(:~
 : The config of the project with `$id`.
 : 
 : @param id The ID of the project to return the config for.
 :)
declare function proj:get-config($id as xs:string)
   as element(mlc:project)?
{
   fn:doc($proj:config-uri)/mlc:console/mlc:projects/mlc:project[@id eq $id]
};

(:~
 : Add a config for an existing project with `$id` and `$dir`.
 : 
 : @param id The ID of the project to add a new config for.
 : 
 : @param dir The directory of the existing project.  It must contain a sub-directory
 : `xproject`, itself containing a file `project.xml`.
 : 
 : @todo Make more checks (does the dir exist, etc.)
 :)
declare function proj:add-config($id as xs:string, $dir as xs:string)
   as empty-sequence()
{
   let $parent := fn:doc($proj:config-uri)/mlc:console/mlc:projects
   return
      if ( fn:exists($parent/mlc:project[@id eq $id]) ) then
         t:error('project-exists', 'There is already a project with the ID: ' || $id)
      else
         xdmp:node-insert-child($parent,
            <project id="{ $id }" xmlns="http://expath.org/ns/ml/console">
               <dir>{ $dir }</dir>
            </project>)
};

declare function proj:get-directory($id as xs:string)
   as xs:string?
{
   proj:get-config($id)/mlc:dir
};

declare function proj:get-descriptor($id as xs:string)
   as element(xp:project)?
{
   proj:get-directory($id)
      ! a:get-from-directory(., 'xproject/project.xml', fn:true())
      / *
};

declare function proj:get-readme($id as xs:string)
   as text()?
{
   proj:get-directory($id)
      ! a:get-from-directory(., 'README.md', fn:false())
};

declare function proj:get-source($id as xs:string, $src as xs:string)
   as text()
{
   proj:get-directory($id)
      ! a:get-from-directory(. || 'src/', $src, fn:false())
};

declare function proj:get-sources($id as xs:string)
   as xs:string*
{
   proj:get-directory($id)
      ! proj:get-sources-1(. || 'src/')
};

(: TODO: Store the module extension in xproject/marklogic.xml.
 :)
declare variable $exts := ('xq', 'xql', 'xqy', 'xqm');

declare function proj:get-sources-1($dir as xs:string)
   as xs:string*
{
   a:browse-files($dir, function($file as xs:string) as xs:string? {
      fn:substring-after($file, $dir)[fn:tokenize(., '\.')[fn:last()] = $exts]
   })
};
