xquery version "3.0";

import module namespace v   = "http://expath.org/ns/ml/console/view"   at "../lib/view.xqy";
import module namespace t   = "http://expath.org/ns/ml/console/tools"  at "../lib/tools.xqy";
import module namespace a   = "http://expath.org/ns/ml/console/admin"  at "../lib/admin.xqy";
import module namespace cfg = "http://expath.org/ns/ml/console/config" at "../lib/config.xqy";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare namespace c    = "http://expath.org/ns/ml/console";
declare namespace err  = "http://www.w3.org/2005/xqt-errors";
declare namespace h    = "http://www.w3.org/1999/xhtml";
declare namespace xdmp = "http://marklogic.com/xdmp";

declare option xdmp:update "true";

(:~
 : TODO: ...
 :)
declare function local:page()
   as element()+
{
   let $id        := t:mandatory-field('container')
   let $ref       := cfg:get-container-ref($id)
   let $container := cfg:get-container($ref)
   let $appserver := a:get-appserver(xs:unsignedLong($container/@appserver))
   return (
      cfg:install-exapth-web-to-appserver($appserver),
      <p>The web container '<a href="show.xq?container={ $ref/fn:string(@id) }">{ $ref/fn:string(c:name) }</a>'
         has been successfully upgraded.</p>,
      <p>Back to <a href="../web.xq">web containers</a>.</p>
   )
};

v:console-page('../', 'web', 'Web containers', local:page#0)
