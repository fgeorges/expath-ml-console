xquery version "3.0";

import module namespace t = "http://expath.org/ns/ml/console/tools" at "../lib/tools.xql";
import module namespace v = "http://expath.org/ns/ml/console/view"  at "../lib/view.xql";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare namespace mlc  = "http://expath.org/ns/ml/console";
declare namespace xp   = "http://expath.org/ns/project";
declare namespace xdmp = "http://marklogic.com/xdmp";

declare function local:page() as element()+
{
   let $id   := t:mandatory-field('id')
   let $conf := fn:doc('http://expath.org/ml/console/config.xml')
   let $proj := $conf/mlc:console/mlc:projects/mlc:project[@id eq $id]
   let $info := xdmp:document-get($proj/mlc:dir || 'xproject/project.xml')/xp:project
   return (
      <p>Project <code>{ xs:string($info/xp:title) }</code>.</p>,
      <p>Available actions:</p>,
      <ul>
         <li><a href="{ $id }/checkup">Check up</a></li>
      </ul>
   )
};

v:console-page('../', 'project', 'Project', local:page#0)
