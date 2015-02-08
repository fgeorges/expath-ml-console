xquery version "3.0";

import module namespace t = "http://expath.org/ns/ml/console/tools"  at "../lib/tools.xql";

declare namespace xdmp = "http://marklogic.com/xdmp";

let $db-id := xs:unsignedLong(t:mandatory-field('database'))
return (
   xdmp:set-response-code(302, 'Found'),
   xdmp:add-response-header('Location', '../db/' || $db-id || '/browse')
)
