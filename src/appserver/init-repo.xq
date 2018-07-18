xquery version "3.0";

import module namespace a = "http://expath.org/ns/ml/console/admin" at "../lib/admin.xqy";
import module namespace t = "http://expath.org/ns/ml/console/tools" at "../lib/tools.xqy";
import module namespace v = "http://expath.org/ns/ml/console/view"  at "../lib/view.xqy";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare namespace c    = "http://expath.org/ns/ml/console";
declare namespace err  = "http://www.w3.org/2005/xqt-errors";
declare namespace xdmp = "http://marklogic.com/xdmp";

declare option xdmp:update "true";

declare function local:page()
   as element()+
{
   let $id-str := t:mandatory-field('id')
   let $id     := xs:unsignedLong($id-str)
   let $as     := a:get-appserver($id)
   let $name   := xs:string($as/a:name)
   let $link   := v:as-link('../' || $as/@id, $name)
   return
      try {
         (: either it contains the element or an error is thrown, but for extra safety...:)
         if ( fn:exists(a:appserver-init-repo($as)/a:repo) ) then
            <p>Package repository correctly initialized for { $link }</p>
         else
            t:error('local-init-repo-01', 'Error initializing the package repository for the app server: ' || $name)
      }
      catch c:repo-already-exists {
         <p><b>Error</b>: package repository already initialized for { $link }</p>
      }
};

v:console-page('../../', 'pkg', 'App server', local:page#0)
