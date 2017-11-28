xquery version "3.0";

module namespace disp = "http://expath.org/ns/ml/console/project/xproject/display";

import module namespace proj = "http://expath.org/ns/ml/console/project" at "../proj-lib.xqy";
import module namespace t    = "http://expath.org/ns/ml/console/tools"   at "../../lib/tools.xqy";
import module namespace v    = "http://expath.org/ns/ml/console/view"    at "../../lib/view.xql";

import module namespace xproject = "http://expath.org/ns/ml/console/project/xproject"
   at "../xproject-lib.xql";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare namespace mlc = "http://expath.org/ns/ml/console";
declare namespace xp  = "http://expath.org/ns/project";

declare function disp:page(
   $id   as xs:string,
   $proj as element(mlc:project),
   $read as xs:string?
) as element()+
{
   let $desc := xproject:descriptor($proj)
   return
      if ( fn:empty($desc) ) then (
         <p>No such project, with ID <code>{ $id }</code>.</p>
      )
      else (
         <p>{ v:proj-link($id, $id) } - { xs:string($desc/xp:title) }.</p>,
         <ul>
            <li><a href="{ $id }/src">Sources</a></li>
            <li><a href="{ $id }/environ">Environments</a></li>
            <li><a href="{ $id }/checkup">Check up</a></li>
         </ul>
      )
};

declare function disp:bin-endpoint($proj as element(mlc:project), $root as xs:string) as xs:string
{
   $root || 'fs/bin?uri=' || $proj/mlc:dir
};
