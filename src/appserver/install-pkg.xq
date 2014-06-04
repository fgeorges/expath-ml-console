xquery version "3.0";

import module namespace a = "http://expath.org/ns/ml/console/admin" at "../lib/admin.xql";
import module namespace t = "http://expath.org/ns/ml/console/tools" at "../lib/tools.xql";
import module namespace v = "http://expath.org/ns/ml/console/view"  at "../lib/view.xql";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare function local:page()
   as element()+
{
   (: the app server :)
   let $id-str   := t:mandatory-field('id')
   let $id       := xs:unsignedLong($id-str)
   let $as       := a:get-appserver($id)
   (: the package :)
   let $xar      := t:mandatory-field('xar')
   let $filename := t:ensure-relative(
                       fn:encode-for-uri(
                          t:mandatory-field-filename('xar')))
   (: save it in the attic and install it :)
   let $stored   := a:appserver-save-in-repo-attic($xar, $filename, $as)
   let $pkg      := a:appserver-install-package($xar, $as)
   (:
   let $override := xs:boolean(t:optional-field('override', 'false'))
   let $pkg      := a:appserver-install-package($xar, $as, $override)
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

v:console-page('../../', 'pkg', 'Install package', local:page#0)
