xquery version "3.0";

import module namespace a = "http://expath.org/ns/ml/console/admin" at "../lib/admin.xql";
import module namespace v = "http://expath.org/ns/ml/console/view"  at "../lib/view.xql";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare namespace mlc  = "http://expath.org/ns/ml/console";
declare namespace xp   = "http://expath.org/ns/project";
declare namespace xdmp = "http://marklogic.com/xdmp";

declare function local:page() as element()+
{
   <p><b>TODO</b>: Implement me...</p>,
   <pre>
- create a project page
- add the possibility of creating a project
- one feature to fixup a project (ideal for development, whilst format evolves...)
   (or sanity check on each project, with errors/warnings, and maybe a fix button for each)</pre>,
   <ul> {
      let $conf := fn:doc('http://expath.org/ml/console/config.xml')
      for $proj in $conf/mlc:console/mlc:projects/mlc:project
      let $info := xdmp:document-get($proj/mlc:dir || 'xproject/project.xml')/xp:project
      return
         <li>
            <a href="project/{ $proj/@id }">{ xs:string($info/xp:title) }</a>
         </li>
   }
   </ul>
};

v:console-page('./', 'project', 'Projects', local:page#0)
