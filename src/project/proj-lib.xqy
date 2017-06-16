xquery version "3.0";

(:~
 : Project information retrieval and manipulation.
 :)
module namespace proj = "http://expath.org/ns/ml/console/project";

import module namespace a = "http://expath.org/ns/ml/console/admin" at "../lib/admin.xqy";
import module namespace t = "http://expath.org/ns/ml/console/tools" at "../lib/tools.xqy";

declare namespace mlc  = "http://expath.org/ns/ml/console";
declare namespace xdmp = "http://marklogic.com/xdmp";

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
   let $proj := proj:projects()[@id eq $id]
   return
      if ( fn:exists($proj[2]) ) then
         t:error('inconsistent',
            'There are more than one project with the ID "' || $id || '" in the project collection')
      else
         $proj
};

(:~
 : Add a config for an existing project with `$id` and `$type`.  Extra info in `$info`.
 : 
 : @param id The ID of the project to add a new config for.
 : 
 : @param type The type of the project (`srcdir`, `xproject`, etc.)
 : 
 : @param info The information to add to the project config.
 : 
 : @todo Make more checks (does the dir exist, etc.)
 : 
 : @todo Specific to XProject projects now, to generalize.
 :)
declare function proj:add-config($id as xs:string, $type as xs:string, $info as element()*)
   as empty-sequence()
{
   let $uri := 'http://expath.org/ml/console/project/' || $id || '/config.xml'
   return
      if ( fn:exists(proj:project($id)) ) then
         t:error('project-exists', 'There is already a project with the ID: ' || $id)
      else if ( fn:doc-available($uri) ) then
         t:error('inconsistent',
            'No project with the ID: ' || $id || ', but the project file exists at: ' || $uri)
      else
         xdmp:document-insert(
            $uri,
            <project id="{ $id }" type="{ $type }" xmlns="http://expath.org/ns/ml/console"> {
               $info
            }
            </project>,
            ( (:permissions:) ),
            $proj:projects-coll)
};

(:~
 : A value to be added to a project config file, with a specific key.
 : 
 : @param name The key, used to construct an element with that name.  Must be a valid NCName.
 : 
 : @param value The value, used as the text content of the new element.
 :)
declare function proj:config-value($name as xs:string, $value as xs:string)
   as element()
{
   element { fn:QName('http://expath.org/ns/ml/console', $name) } { $value }
};

declare function proj:directory($proj as element(mlc:project))
   as xs:string
{
   $proj/mlc:dir
};
