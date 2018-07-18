xquery version "3.0";

(:~
 : Delete metadata from a specific document in a specific database.
 :
 : Accept the following request fields (all mandatory, except "redirect"):
 :   - key: the key of the metadata on the document
 :   - uri: the URI of the document
 :   - database: the ID of the database containing the document
 :   - redirect: whether to redirect to the document's page in browse area
 :)

import module namespace a = "http://expath.org/ns/ml/console/admin" at "../lib/admin.xqy";
import module namespace t = "http://expath.org/ns/ml/console/tools" at "../lib/tools.xqy";
import module namespace v = "http://expath.org/ns/ml/console/view"  at "../lib/view.xqy";

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
   let $db       := t:mandatory-field('database')
   let $uri      := t:mandatory-field('uri')
   let $key      := t:mandatory-field('key')
   let $redirect := xs:boolean(t:optional-field('redirect', 'false'))
   return
      if ( fn:not(a:exists-on-database($db, $uri)) ) then (
         <p><b>Error</b>: The document "{ $uri }" does not exist on the
            database "{ $db }".</p>
      )
      else (
         t:query($db, function() {
            xdmp:document-remove-metadata($uri, $key)
         }),
         if ( $redirect ) then (
            v:redirect(
               '../db/' || $db || '/doc?uri=' || fn:encode-for-uri($uri))
         )
         else (
            <p>Metadata "<code>{ $key }</code>" successfully removed from
               "<code>{ $uri }</code>".</p>,
            <p>Back to <a href="docs">document manager</a>.</p>
         )
      )
};

v:console-page('../', 'tools', 'Tools', local:page#0)
