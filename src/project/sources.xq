xquery version "3.0";

import module namespace proj = "http://expath.org/ns/ml/console/project" at "proj-lib.xql";
import module namespace a    = "http://expath.org/ns/ml/console/admin"   at "../lib/admin.xql";
import module namespace t    = "http://expath.org/ns/ml/console/tools"   at "../lib/tools.xql";
import module namespace v    = "http://expath.org/ns/ml/console/view"    at "../lib/view.xql";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare function local:page() as element()+
{
   let $id := t:mandatory-field('id')
   return (
      <p>Back to { v:proj-link('../' || $id, $id) }</p>,
      <ul> {
         proj:get-sources($id) ! <li><a href="src/{ . }">{ . }</a></li>
      }
      </ul>
   )
};

v:console-page('../../', 'project', 'Sources', local:page#0)
