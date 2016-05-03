xquery version "3.0";

(:~
 : Information retrieval and manipulation for all project types.
 :)
module namespace global = "http://expath.org/ns/ml/console/project/global";

import module namespace srcdir   = "http://expath.org/ns/ml/console/project/srcdir"   at "srcdir-lib.xql";
import module namespace xproject = "http://expath.org/ns/ml/console/project/xproject" at "xproject-lib.xql";

import module namespace t = "http://expath.org/ns/ml/console/tools" at "../lib/tools.xql";

declare namespace mlc = "http://expath.org/ns/ml/console";

declare function global:source($proj as element(mlc:project), $src as xs:string) as text()?
{
   if ( $proj/@type eq 'srcdir' ) then
      srcdir:source($proj, $src)
   else if ( $proj/@type eq 'xproject' ) then
      xproject:source($proj, $src)
   else
      t:error('unknown', 'Unknown type of project: ' || $proj/@type)
};

declare function global:source-lang($proj as element(mlc:project), $src as xs:string) as xs:string?
{
   if ( $proj/@type eq 'srcdir' ) then
      srcdir:source-lang($proj, $src)
   else if ( $proj/@type eq 'xproject' ) then
      xproject:source-lang($proj, $src)
   else
      t:error('unknown', 'Unknown type of project: ' || $proj/@type)
};
