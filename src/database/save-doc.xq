xquery version "3.0";

import module namespace a = "http://expath.org/ns/ml/console/admin" at "../lib/admin.xql";
import module namespace t = "http://expath.org/ns/ml/console/tools" at "../lib/tools.xql";

declare namespace xdmp = "http://marklogic.com/xdmp";

(: TODO: Use the functions from t:* ! :)
let $id  := t:mandatory-field('id')
let $uri := t:mandatory-field('uri')
let $doc := t:mandatory-field('doc')
let $db  := xs:unsignedLong($id)
return (
   a:eval-on-database(
      $db,
      'declare namespace xdmp = "http://marklogic.com/xdmp";
       declare variable $uri external;
       declare variable $doc external;
       xdmp:document-insert($uri, xdmp:unquote($doc))',
      (fn:QName('', 'uri'),  $uri,
       fn:QName('', 'doc'),  $doc)),
   'Query saved in DB ' || xdmp:database-name($db) || ', at ' || $uri
)
