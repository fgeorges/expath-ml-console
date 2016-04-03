xquery version "3.0";

import module namespace proj = "http://expath.org/ns/ml/console/project" at "proj-lib.xql";
import module namespace a    = "http://expath.org/ns/ml/console/admin"   at "../lib/admin.xql";
import module namespace t    = "http://expath.org/ns/ml/console/tools"   at "../lib/tools.xql";
import module namespace v    = "http://expath.org/ns/ml/console/view"    at "../lib/view.xql";

import module namespace srcdir   = "http://expath.org/ns/ml/console/project/srcdir/checkup"
   at "srcdir/checkup.xql";
import module namespace xproject = "http://expath.org/ns/ml/console/project/xproject/checkup"
   at "xproject/checkup.xql";

declare default element namespace "http://www.w3.org/1999/xhtml";

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

declare function local:string($item as item()?, $exists as xs:boolean) as element()
{
   if ( $exists ) then
      <span class="label alert-success">{ xs:string($item) }</span>
   else
      <span class="label alert-danger">empty</span>
};

declare function local:page() as element()+
{
   let $id   := t:mandatory-field('id')
   let $proj := proj:project($id)
   return (
      <p>Back to { v:proj-link('../' || $id, $id) }</p>,
      <p>Project element: { local:one($proj) }</p>,
      if ( $proj/@type eq 'srcdir' ) then
         srcdir:page($id, $proj, local:one#1, local:exists#1, local:string#2)
      else if ( $proj/@type eq 'xproject' ) then
         xproject:page($id, $proj, local:one#1, local:exists#1, local:string#2)
      else if ( fn:exists($proj) ) then
         t:error('unknown', 'Unknown type of project: ' || $proj/@type)
      else
         ()
   )
};

v:console-page('../../', 'project', 'Project', local:page#0)
