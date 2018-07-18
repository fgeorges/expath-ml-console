xquery version "3.0";

(:~
 : Information retrieval and manipulation for all project types.
 :)
module namespace global = "http://expath.org/ns/ml/console/project/global";

import module namespace dbdir    = "http://expath.org/ns/ml/console/project/dbdir"    at "dbdir-lib.xqy";
import module namespace srcdir   = "http://expath.org/ns/ml/console/project/srcdir"   at "srcdir-lib.xqy";
import module namespace xproject = "http://expath.org/ns/ml/console/project/xproject" at "xproject-lib.xqy";

import module namespace t = "http://expath.org/ns/ml/console/tools" at "../lib/tools.xqy";

declare namespace mlc = "http://expath.org/ns/ml/console";

declare function global:title($proj as element(mlc:project)) as xs:string?
{
   if ( $proj/@type eq 'dbdir' ) then
      dbdir:title($proj)
   else if ( $proj/@type eq 'srcdir' ) then
      srcdir:title($proj)
   else if ( $proj/@type eq 'xproject' ) then
      xproject:title($proj)
   else
      t:error('unknown', 'Unknown type of project: ' || $proj/@type)
};

declare function global:info($proj as element(mlc:project)) as item()*
{
   if ( $proj/@type eq 'dbdir' ) then
      dbdir:info($proj)
   else if ( $proj/@type eq 'srcdir' ) then
      srcdir:info($proj)
   else if ( $proj/@type eq 'xproject' ) then
      xproject:info($proj)
   else
      t:error('unknown', 'Unknown type of project: ' || $proj/@type)
};

(: TODO: Shouldn't we use this:source() directly...? :)
declare function global:readme($proj as element(mlc:project)) as text()?
{
   if ( $proj/@type eq 'dbdir' ) then
      dbdir:readme($proj)
   else if ( $proj/@type eq 'srcdir' ) then
      srcdir:readme($proj)
   else if ( $proj/@type eq 'xproject' ) then
      xproject:readme($proj)
   else
      t:error('unknown', 'Unknown type of project: ' || $proj/@type)
};

declare function global:source($proj as element(mlc:project), $src as xs:string) as text()?
{
   if ( $proj/@type eq 'dbdir' ) then
      dbdir:source($proj, $src)
   else if ( $proj/@type eq 'srcdir' ) then
      srcdir:source($proj, $src)
   else if ( $proj/@type eq 'xproject' ) then
      xproject:source($proj, $src)
   else
      t:error('unknown', 'Unknown type of project: ' || $proj/@type)
};

declare function global:source-lang($proj as element(mlc:project), $src as xs:string) as xs:string?
{
   if ( $proj/@type eq 'dbdir' ) then
      dbdir:source-lang($proj, $src)
   else if ( $proj/@type eq 'srcdir' ) then
      srcdir:source-lang($proj, $src)
   else if ( $proj/@type eq 'xproject' ) then
      xproject:source-lang($proj, $src)
   else
      t:error('unknown', 'Unknown type of project: ' || $proj/@type)
};
