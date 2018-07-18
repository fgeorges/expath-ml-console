xquery version "3.0";

import module namespace a = "http://expath.org/ns/ml/console/admin" at "../lib/admin.xql";
import module namespace t = "http://expath.org/ns/ml/console/tools" at "../lib/tools.xql";
import module namespace v = "http://expath.org/ns/ml/console/view"  at "../lib/view.xql";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare namespace xdmp = "http://marklogic.com/xdmp";

declare option xdmp:update "true";

(:~
 : TODO: Display a proper error page if there is no such params.
 :
 : @param kind Either `doc` or `dir`.
 :)
declare function local:uris-to-delete($kind as xs:string)
   as xs:string*
{
   xdmp:get-request-field-names()[fn:starts-with(., $kind || '-to-delete-')]
      ! xdmp:get-request-field(.)
};

(:~
 : The overall page function.
 :)
declare function local:page()
   as element()+
{
   (: TODO: Check the params are there, and validate them... :)
   let $name     := t:mandatory-field('name')
   let $db       := a:get-database($name)
   let $back-url := t:mandatory-field('back-url')
   let $docs     := local:uris-to-delete('doc')
   let $dirs     := local:uris-to-delete('dir')
   return (
      a:remove-docs-and-dirs($db, $docs, $dirs),
      t:when(fn:exists($dirs), (
         <p>Directories successfully deleted from:</p>,
         <ul>{ $dirs ! <li>{ . }</li> }</ul>)),
      t:when(fn:exists($docs), (
         <p>Documents successfully deleted from:</p>,
         <ul>{ $docs ! <li>{ . }</li> }</ul>)),
      <p>Back to <a href="{ $back-url }">the directory</a>.</p>
   )
};

v:console-page('../../', 'tools', 'Browse', local:page#0)
