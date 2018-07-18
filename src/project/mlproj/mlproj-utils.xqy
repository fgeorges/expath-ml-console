xquery version "3.0";

module namespace utils = "http://expath.org/ns/ml/console/mlproj/utils";

import module namespace a = "http://expath.org/ns/ml/console/admin" at "../../lib/admin.xqy";

declare namespace ns   = "http://expath.org/ns/project";
declare namespace xdmp = "http://marklogic.com/xdmp";
declare namespace map  = "http://marklogic.com/xdmp/map";

declare function utils:do-project-xml($path as xs:string)
   as item((: map:map :))
{
   let $doc  := a:get-from-filesystem($path, fn:true())
   let $proj := $doc/ns:project
   return
      if ( fn:empty($doc) ) then
         fn:error(((: TODO: Use proper error mgmt... :)), 'Bad project.xml, no document: ' || $path)
      else if ( fn:empty($proj) ) then
         fn:error(((: TODO: Use proper error mgmt... :)), 'Bad project.xml, no project element: ' || $path)
      else if ( fn:empty($proj/@abbrev) ) then
         fn:error(((: TODO: Use proper error mgmt... :)), 'Bad project.xml, no abbrev: ' || $path)
      else
         let $res := map:new(())
         let $_   := $proj/@abbrev  ! map:put($res, 'abbrev',  xs:string(.))
         let $_   := $proj/@name    ! map:put($res, 'mame',    xs:string(.))
         let $_   := $proj/@version ! map:put($res, 'version', xs:string(.))
         let $_   := $proj/ns:title ! map:put($res, 'title',   xs:string(.))
         return
            $res
};
