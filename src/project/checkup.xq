xquery version "3.0";

import module namespace t = "http://expath.org/ns/ml/console/tools" at "../lib/tools.xql";
import module namespace v = "http://expath.org/ns/ml/console/view"  at "../lib/view.xql";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare namespace mlc  = "http://expath.org/ns/ml/console";
declare namespace xp   = "http://expath.org/ns/project";
declare namespace err  = "http://www.w3.org/2005/xqt-errors";
declare namespace xdmp = "http://marklogic.com/xdmp";

declare function local:exists($item as item()?) as element()
{
   if ( fn:exists($item) ) then
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

declare function local:file($path as xs:string) as document-node()?
{
   try {
      xdmp:document-get($path)
   }
   catch * {
      if ( fn:contains($err:description, 'No such file or directory') ) then
         ()
      else
         fn:error((), $err:description,  $err:additional)
   }
};

declare function local:page() as element()+
{
   let $id       := t:mandatory-field('id')
   let $conf     := fn:doc('http://expath.org/ml/console/config.xml')
   let $projects := $conf/mlc:console/mlc:projects/mlc:project
   return (
      <p>Back to { v:proj-link('../' || $id, $id) }</p>,
      <p>Console config file: { local:exists($conf) }</p>,
      <p>Config root element: { local:exists($conf/mlc:console) }</p>,
      <p>Project elements: { local:exists($projects) }</p>,
      if ( fn:exists($projects) ) then local:page-1($id, $projects) else ()
   )
};

declare function local:page-1($id as xs:string, $projects as element(mlc:project)+) as element()+
{
   let $proj := $projects[@id eq $id]
   let $path := $proj/mlc:dir || 'xproject/project.xml'
   let $file := local:file($path)
   let $info := $file/xp:project
   return (
      <p>Project element: { local:exists($proj) }</p>,
      <p>Project dir: { local:string($proj/mlc:dir) }</p>,
      <p>Project file: { local:string($path, fn:exists($file)) }</p>,
      <p>Project element: { local:exists($info) }</p>,
      <p>Title: { local:string($info/xp:title) }</p>
   )
};

v:console-page('../../', 'project', 'Project', local:page#0)
