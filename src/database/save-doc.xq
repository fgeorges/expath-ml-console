xquery version "3.0";

import module namespace a = "http://expath.org/ns/ml/console/admin" at "../lib/admin.xql";
import module namespace t = "http://expath.org/ns/ml/console/tools" at "../lib/tools.xql";

declare namespace map  = "http://marklogic.com/xdmp/map";
declare namespace xdmp = "http://marklogic.com/xdmp";

let $id   := t:mandatory-field('id')
let $uri  := t:mandatory-field('uri')
let $doc  := t:mandatory-field('doc')
let $type := t:mandatory-field('type')
let $db   := xs:unsignedLong($id)
return (
   a:eval-on-database(
      $db,
      'declare namespace xdmp = "http://marklogic.com/xdmp";
       declare variable $uri  external;
       declare variable $doc  external;
       declare variable $type external;
       if ( $type eq "text" ) then
          xdmp:document-insert($uri, xdmp:unquote($doc, (), "format-json"))
       else if ( $type eq "json" ) then
          xdmp:document-insert($uri, text { $doc })
       else
          xdmp:document-insert($uri, xdmp:unquote($doc))',
      map:new((
         map:entry('uri',  $uri),
         map:entry('doc',  $doc),
         map:entry('type', $type)))),
   'Document saved in DB ' || xdmp:database-name($db) || ', at ' || $uri
)
