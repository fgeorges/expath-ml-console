xquery version "3.0";

module namespace env = "http://expath.org/ns/ml/console/environments";

import module namespace v = "http://expath.org/ns/ml/console/view" at "../lib/view.xql";

declare namespace xdmp = "http://marklogic.com/xdmp";
declare namespace map  = "http://marklogic.com/xdmp/map";
declare namespace json = "http://marklogic.com/xdmp/json";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare function env:environs($envs)
   as element(li)*
{
   for $env   in json:array-values($envs)
   let $name  := map:get($env, 'name')
   let $title := map:get($env, 'title')
   order by $name
   return
      <li> {
         $name,
         (' - ' || $title)[$title]
      }
      </li>
};

declare function env:page($leaves, $libs)
{
   v:console-page('../../', 'project', 'environ', function() {
      <ul> {
         env:environs($leaves),
         env:environs($libs)
      }
      </ul>
   })
};
