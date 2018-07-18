xquery version "3.0";

module namespace env = "http://expath.org/ns/ml/console/project/xproject/environ";

import module namespace proj = "http://expath.org/ns/ml/console/project" at "../proj-lib.xqy";
import module namespace a    = "http://expath.org/ns/ml/console/admin"   at "../../lib/admin.xqy";

declare namespace dir = "http://marklogic.com/xdmp/directory";

declare function env:environs($id as xs:string)
   as xs:string+
{
   let $p     := proj:project($id)
   let $dir   := proj:directory($p)
   let $files := a:get-directory($dir || 'xproject/mlenvs/')/dir:entry
   return
      $files/dir:pathname[fn:ends-with(., '.json')]
};
