xquery version "3.0";

import module namespace b = "http://expath.org/ns/ml/console/browse" at "browse-lib.xql";
import module namespace t = "http://expath.org/ns/ml/console/tools"  at "../lib/tools.xql";
import module namespace v = "http://expath.org/ns/ml/console/view"   at "../lib/view.xql";

declare function local:json($res as element()*)
{
   '['
   || fn:string-join($res ! ('&#10;   "' || . || '"'), ', ')
   || '&#10;]'
};

(: TODO: How to solve the separator thing here??? :)
(: Use all the schemes from dbc:config-uri-schemes($db)...? :)
let $sep    := '/'
let $length := 10

let $name    := t:mandatory-field('name')
let $input   := t:mandatory-field('input')
let $type    := t:mandatory-field('type')
let $lexicon := t:when(fn:starts-with($type, 'c'), v:ensure-coll-lexicon#2, v:ensure-uri-lexicon#2)
return
   v:ensure-db($name, function($db) {
      $lexicon($db, function() {
         t:query($db, function() {
            local:json(
               switch ( $type )
                  (: TODO: Ensure there is a URI lexicon, collection lexicon, or triple index when needed. :)
                  case 'dir'  return b:get-matching-dir($input, $sep, $length)
                  case 'cdir' return b:get-matching-cdir($input, $sep, $length)
                  case 'doc'  return b:get-matching-doc($input, $sep, $length)
                  case 'cdoc' return b:get-matching-cdoc($input, $sep, $length)
                  case 'rsrc' return b:get-matching-rsrc($input, $length)
                  default return t:error('unkown-enum', 'Unknown URI type: ' || $type)
            )
         })
      })
   })
