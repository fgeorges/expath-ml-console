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
 : The collection for project descriptors.
 :)
declare variable $proj:projects-coll := 'http://expath.org/ml/console/projects';

(:~
 : All project descriptors.
 : 
 : @return A sequence of project elements.
 :)
declare function proj:projects()
   as element(mlc:project)*
{
   fn:collection($proj:projects-coll)/mlc:project
};

(:~
 : The ID of all projects.
 : 
 : @return A sequence of IDs.
 :)
declare function proj:project-ids()
   as xs:string*
{
   proj:projects()/@id
};

(:~
 : The config of the project with `$id`.
 : 
 : @param id The ID of the project to return the config for.
 :)
declare function proj:project($id as xs:string)
   as element(mlc:project)?
{
   proj:projects()[@id eq $id]
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
 : 
 : @todo Specific to XProject projects now, to generalize.
 :)
declare function proj:add-config($id as xs:string, $dir as xs:string)
   as empty-sequence()
{
   if ( fn:exists(proj:project($id)) ) then
      t:error('project-exists', 'There is already a project with the ID: ' || $id)
   else
      xdmp:document-insert(
         'http://expath.org/ml/console/project/' || $id || '.xml',
         <project id="{ $id }" type="xproject" xmlns="http://expath.org/ns/ml/console">
            <dir>{ $dir }</dir>
         </project>,
         ( (:permissions:) ),
         $proj:projects-coll)
};

declare function proj:directory($proj as element(mlc:project))
   as xs:string
{
   $proj/mlc:dir
};

declare function proj:descriptor($proj as element(mlc:project))
   as element(xp:project)?
{
   proj:directory($proj)
      ! a:get-from-directory(., 'xproject/project.xml', fn:true())
      / *
};

declare function proj:readme($proj as element(mlc:project))
   as text()?
{
   proj:directory($proj)
      ! a:get-from-directory(., 'README.md', fn:false())
};

declare function proj:source($proj as element(mlc:project), $src as xs:string)
   as text()?
{
   proj:directory($proj)
      ! a:get-from-directory(. || 'src/', $src, fn:false())
};

declare function proj:sources($proj as element(mlc:project))
   as xs:string*
{
   proj:directory($proj)
      ! proj:sources-1(. || 'src/')
};

(: TODO: Store the module extension in xproject/marklogic.xml.
 :)
declare variable $exts := ('xq', 'xql', 'xqy', 'xqm');

declare function proj:sources-1($dir as xs:string)
   as xs:string*
{
   a:browse-files($dir, function($file as xs:string) as xs:string? {
      fn:substring-after($file, $dir)[fn:tokenize(., '\.')[fn:last()] = $exts]
   })
};
