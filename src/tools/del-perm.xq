xquery version "3.0";

(:~
 : Delete permission from a specific document in a specific database.
 :
 : Accept the following request fields (all mandatory, except "redirect"):
 :   - capability: the capability of the permission to delete
 :   - role: the role name of the permission to delete
 :   - uri: the URI of the document
 :   - database: the ID of the database containing the document
 :   - redirect: whether to redirect to the document's page in browse area
 :)

import module namespace a = "http://expath.org/ns/ml/console/admin" at "../lib/admin.xql";
import module namespace t = "http://expath.org/ns/ml/console/tools" at "../lib/tools.xql";
import module namespace v = "http://expath.org/ns/ml/console/view"  at "../lib/view.xql";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare namespace map  = "http://marklogic.com/xdmp/map";
declare namespace xdmp = "http://marklogic.com/xdmp";

declare option xdmp:update "true";

(:~
 : The overall page function.
 :)
declare function local:page()
   as element()+
{
   (: TODO: Check the params are there, and validate them... :)
   let $db-id      := xs:unsignedLong(t:mandatory-field('database'))
   let $db         := a:get-database($db-id)
   let $uri        := t:mandatory-field('uri')
   let $capability := t:mandatory-field('capability')
   let $role       := t:mandatory-field('role')
   let $redirect   := xs:boolean(t:optional-field('redirect', 'false'))
   return
      if ( fn:not(a:exists-on-database($db, $uri)) ) then (
         <p><b>Error</b>: The document "{ $uri }" does not exist on the
            database "{ xs:string($db/a:name) }".</p>
      )
      else (
         a:eval-on-database(
            $db,
            'declare namespace xdmp = "http://marklogic.com/xdmp";
             declare variable $uri  as xs:string external;
             declare variable $cap  as xs:string external;
             declare variable $role as xs:string external;
             xdmp:document-remove-permissions(
                $uri,
                xdmp:permission($role, $cap))',
            map:new((
               map:entry('uri',  $uri),
               map:entry('cap',  $capability),
               map:entry('role', $role)))),
         if ( $redirect ) then (
            v:redirect(
               '../db/' || $db-id || '/browse'
               || '/'[fn:not(fn:starts-with($uri, '/'))]
               || fn:string-join(fn:tokenize($uri, '/') ! fn:encode-for-uri(.), '/'))
         )
         else (
            <p>Permission "<code>{ $capability }</code>" successfully removed from
               "<code>{ $uri }</code>" for "<code>{ $role }</code>".</p>,
            <p>Back to <a href="docs">document manager</a>.</p>
         )
      )
};

v:console-page('../', 'tools', 'Tools', local:page#0)
