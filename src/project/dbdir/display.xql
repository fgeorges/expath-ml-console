xquery version "3.0";

module namespace disp = "http://expath.org/ns/ml/console/project/dbdir/display";

import module namespace v = "http://expath.org/ns/ml/console/view" at "../../lib/view.xql";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare namespace mlc = "http://expath.org/ns/ml/console";

declare function disp:page($proj as element(mlc:project)) as element()+
{
   <p>{ v:proj-link($proj/@id, $proj/@id) } - In <code>{ xs:string($proj/mlc:db) }</code>.</p>,
   $proj/mlc:title ! <p>{ xs:string(.) }</p>,
   <ul>
      <li><a href="{ $proj/@id }/src">Sources</a></li>
      <li><a href="{ $proj/@id }/checkup">Check up</a></li>
   </ul>
};

declare function disp:bin-endpoint($proj as element(mlc:project), $root as xs:string) as xs:string
{
   $root || 'db/' || $proj/mlc:db || '/bin?uri=' || $proj/mlc:root
};
