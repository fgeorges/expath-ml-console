xquery version "3.0";

import module namespace proj = "http://expath.org/ns/ml/console/project" at "proj-lib.xqy";
import module namespace t    = "http://expath.org/ns/ml/console/tools"   at "../lib/tools.xqy";
import module namespace v    = "http://expath.org/ns/ml/console/view"    at "../lib/view.xqy";

import module namespace dbdir    = "http://expath.org/ns/ml/console/project/dbdir"    at "dbdir-lib.xqy";
import module namespace srcdir   = "http://expath.org/ns/ml/console/project/srcdir"   at "srcdir-lib.xqy";
import module namespace xproject = "http://expath.org/ns/ml/console/project/xproject" at "xproject-lib.xqy";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare namespace mlc = "http://expath.org/ns/ml/console";

declare function local:sources($proj as element(mlc:project)) as xs:string*
{
   if ( $proj/@type eq 'dbdir' ) then
      dbdir:sources($proj)
   else if ( $proj/@type eq 'srcdir' ) then
      srcdir:sources($proj)
   else if ( $proj/@type eq 'xproject' ) then
      xproject:sources($proj)
   else
      t:error('unknown', 'Unknown type of project: ' || $proj/@type)
};

(: TODO: Order by path...!
 :)
declare function local:page() as element()+
{
   let $id := t:mandatory-field('id')
   return (
      <p>Back to { v:proj-link('../' || $id, $id) }</p>,
      <ul> {
         let $proj := proj:project($id)
         for $src  in local:sources($proj)
         order by $src
         return
            <li><a href="src/{ $src }">{ $src }</a></li>
      }
      </ul>
   )
};

v:console-page('../../', 'project', 'Sources', local:page#0)
