xquery version "3.0";

import module namespace a = "http://expath.org/ns/ml/console/admin" at "../lib/admin.xql";
import module namespace t = "http://expath.org/ns/ml/console/tools" at "../lib/tools.xql";
import module namespace v = "http://expath.org/ns/ml/console/view"  at "../lib/view.xql";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare namespace pp = "http://expath.org/ns/repo/packages";

(:~
 : The overall page function.
 :)
declare function local:page()
   as element()+
{
   (: the app server :)
   let $id-str  := t:mandatory-field('id')
   let $id      := xs:unsignedLong($id-str)
   let $as      := a:get-appserver($id)
   (: the package (id, name and version) :)
   let $pkg-id  := t:optional-field('pkg')
   let $name    := t:optional-field('name')
   let $version := t:optional-field('version')
   let $pkg     := local:install($pkg-id, $name, $version, $as)
   (:
   let $override := xs:boolean(t:optional-field('override', 'false'))
   let $pkg      := local:install($pkg-id, $name, $version, $as, $override)
   :)
   return (
      if ( fn:exists($pkg) ) then
         <p>Package '{ $filename }' successfully installed into the repository associated
            to the app server '{ $as/xs:string(a:name) }', within the package directory
            '{ $pkg/xs:string(@dir) }'.</p>
      else
         (: TODO: Provide more accurate info! :)
         (: TODO: Use try/catch instead...! :)
         <p>Package '{ $filename }' NOT installed into the repository associated to the app
            server '{ $as/xs:string(a:name) }'.  Did it already exist?</p>,
      <p>Back to the app server <a href="../{ $as/@id }">{ $as/xs:string(a:name) }</a>.</p>
   )
};

declare function local:install(
   $id      as xs:string,
   $name    as xs:string,
   $version as xs:string,
   $as      as element(a:appserver)
) as element(pp:package)?
{
   if ( fn:exists($id[.]) and fn:exists($name[.]) ) then
      <p><b>Error</b>: Both CXAN ID and package name provided: resp. '{ $id }'
         and '{ $name }'.</p>
   else if ( fn:exists($id[.]) ) then
      a:appserver-install-cxan-id($id, $version, $as, $override)
   else if ( fn:exists($name[.]) ) then
      a:appserver-install-cxan-name($id, $version, $as, $override)
   else
      <p><b>Error</b>: No CXAN ID nor package name provided.</p>
};

v:console-page('../../', 'pkg', 'Install package', local:page#0)
