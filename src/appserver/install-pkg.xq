xquery version "3.0";

import module namespace a = "http://expath.org/ns/ml/console/admin" at "../lib/admin.xqy";
import module namespace t = "http://expath.org/ns/ml/console/tools" at "../lib/tools.xql";
import module namespace v = "http://expath.org/ns/ml/console/view"  at "../lib/view.xql";

declare default element namespace "http://www.w3.org/1999/xhtml";

(:~
 : The overall page function.
 :)
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
   let $link     := v:as-link('../' || $as/@id, $as/a:name)
   return (
      if ( fn:exists($pkg) ) then
         <p>Package <code>{ $filename }</code> successfully installed into the
            repository associated to { $link }, within the package directory
            <code>{ $pkg/xs:string(@dir) }</code>.</p>
      else
         (: TODO: Provide more accurate info! :)
         (: TODO: Use try/catch instead...! :)
         <p>Package <code>{ $filename }</code> NOT installed into the repository
            associated to { $link }.  Did it already exist?</p>,
      <p>Back to { $link }</p>
   )
};

v:console-page('../../', 'pkg', 'Install package', local:page#0)
