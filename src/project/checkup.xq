xquery version "3.0";

import module namespace proj = "http://expath.org/ns/ml/console/project" at "proj-lib.xql";
import module namespace a    = "http://expath.org/ns/ml/console/admin"   at "../lib/admin.xql";
import module namespace t    = "http://expath.org/ns/ml/console/tools"   at "../lib/tools.xql";
import module namespace v    = "http://expath.org/ns/ml/console/view"    at "../lib/view.xql";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare namespace mlc = "http://expath.org/ns/ml/console";
declare namespace xp  = "http://expath.org/ns/project";

declare function local:one($seq as item()*) as element()
{
   if ( fn:exists($seq[2]) ) then
      <span class="label alert-danger">more than one</span>
   else
      local:exists($seq)
};

declare function local:exists($seq as item()*) as element()
{
   if ( fn:exists($seq) ) then
      <span class="label alert-success">exists</span>
   else
      <span class="label alert-danger">empty</span>
};

declare function local:string($item as item()?) as element()
{
   local:string($item, fn:exists($item))
};

declare function local:string($item as item()?, $ok as xs:boolean) as element()
{
   if ( $ok ) then
      <span class="label alert-success">{ xs:string($item) }</span>
   else
      <span class="label alert-danger">empty</span>
};

declare function local:page() as element()+
{
   let $id       := t:mandatory-field('id')
   let $conf     := fn:doc('http://expath.org/ml/console/config.xml')
   let $projects := $conf/mlc:console/mlc:projects/mlc:project
   return (
      <p>Back to { v:proj-link('../' || $id, $id) }</p>,
      <p>Console config file: { local:one($conf) }</p>,
      <p>Config root element: { local:one($conf/mlc:console) }</p>,
      <p>Project elements: { local:exists($projects) }</p>,
      if ( fn:exists($projects) ) then local:page-1($id, $projects) else ()
   )
};

declare function local:page-1(
   $id       as xs:string, 
   $projects as element(mlc:project)+
) as element()+
{
   let $proj := $projects[@id eq $id]
   let $desc := proj:descriptor($proj)
   let $dir  := proj:directory($proj)
   return (
      <p>Project element: { local:one($proj) }</p>,
      <p>Project dir: { $dir ! local:string(., a:file-exists(.)) }</p>,
      <p>Project file: {
          local:string($dir || 'xproject/project.xml', fn:exists($desc))
      } </p>,
      <p>Title: { local:string($desc/xp:title) }</p>
   )
};

v:console-page('../../', 'project', 'Project', local:page#0)
