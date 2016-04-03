xquery version "3.0";

module namespace disp = "http://expath.org/ns/ml/console/project/srcdir/display";

import module namespace v = "http://expath.org/ns/ml/console/view" at "../../lib/view.xql";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare namespace mlc = "http://expath.org/ns/ml/console";

declare function disp:page(
   $id   as xs:string,
   $proj as element(mlc:project),
   $read as xs:string?
) as element()+
{
   <p>{ v:proj-link($id, $id) } - In <code>{ xs:string($proj/mlc:dir) }</code>.</p>,
   <ul>
      <li><a href="{ $id }/src">Sources</a></li>
      <li><a href="{ $id }/checkup">Check up</a></li>
   </ul>
};
