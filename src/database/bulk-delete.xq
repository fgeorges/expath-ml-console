xquery version "3.0";

import module namespace a = "http://expath.org/ns/ml/console/admin" at "../lib/admin.xql";
import module namespace t = "http://expath.org/ns/ml/console/tools" at "../lib/tools.xql";
import module namespace v = "http://expath.org/ns/ml/console/view"  at "../lib/view.xql";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare namespace xdmp = "http://marklogic.com/xdmp";

(:~
 : TODO: Display a proper error page if there is no such params.
 :)
declare function local:uris-to-delete()
   as xs:string+
{
   xdmp:get-request-field-names()[fn:starts-with(., 'uri-to-delete-')]
      ! xdmp:get-request-field(.)
};

(:~
 : The overall page function.
 :)
declare function local:page()
   as element()+
{
   (: TODO: Check the params are there, and validate them... :)
   let $db-id    := xs:unsignedLong(t:mandatory-field('database'))
   let $db       := a:get-database($db-id)
   let $back-url := t:mandatory-field('back-url')
   let $uris     := local:uris-to-delete()
   return (
      a:remove-docs-and-dirs($db, $uris),
      <p>Documents and/or directories successfully deleted from:</p>,
      <ul>{ $uris ! <li>{ . }</li> }</ul>,
      <p>Back to <a href="{ $back-url }">the directory</a>.</p>
   )
};

v:console-page('../../', 'tools', 'Browse', local:page#0)
