xquery version "3.0";

import module namespace a = "http://expath.org/ns/ml/console/admin" at "../lib/admin.xql";
import module namespace t = "http://expath.org/ns/ml/console/tools" at "../lib/tools.xql";

declare namespace map  = "http://marklogic.com/xdmp/map";
declare namespace xdmp = "http://marklogic.com/xdmp";

(:~
 : Update an existing, empty document.
 :)
declare function local:insert($doc as document-node(), $node as node())
{
   typeswitch ( $node )
      case document-node() return
         xdmp:node-insert-child($doc, $node/node())
      default return
         xdmp:node-insert-child($doc, $node)
};

(:~
 : Update an existing, non-empty document.
 :)
declare function local:replace($doc as document-node(), $node as node())
{
   typeswitch ( $node )
      case document-node() return
         xdmp:node-replace($doc/node(), $node/node())
      default return
         xdmp:node-replace($doc/node(), $node)
};

(:~
 : Save a new document or update an existing one.
 :)
declare function local:save-it($uri as xs:string, $node as node())
{
   let $doc := fn:doc($uri)
   return
      (: if $doc exists, keep the doc node but replace its content :)
      if ( fn:exists($doc) ) then
         (: empty doc node :)
         if ( fn:empty($doc/node()) ) then
            local:insert($doc, $node)
         (: non-empty doc node :)
         else
            local:replace($doc, $node)
      (: if $doc does not exist, create it :)
      else
         xdmp:document-insert($uri, $node)
};

(:~
 : Save a new document or update an existing one, provided as a string, based on its type.
 :)
declare function local:save($uri as xs:string, $doc as xs:string, $type as xs:string)
{
   switch ( $type )
      case 'text' return
         local:save-it($uri, xdmp:unquote($doc, (), 'format-json'))
      case 'json' return
         local:save-it($uri, text { $doc })
      case 'xml' return
         local:save-it($uri, xdmp:unquote($doc))
      default return
         t:error('invalid-param', 'Unknown document type: ' || $type)
};

let $uri  := t:mandatory-field('uri')
let $doc  := t:mandatory-field('doc')
let $type := t:mandatory-field('type')
let $id   := t:mandatory-field('id')
let $db   := xs:unsignedLong($id)
return (
   a:update-database($db, function() {
      local:save($uri, $doc, $type)
   }),
   'Document saved in DB ' || xdmp:database-name($db) || ', at ' || $uri
)
