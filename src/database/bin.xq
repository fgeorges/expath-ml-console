xquery version "3.0";

import module namespace t = "http://expath.org/ns/ml/console/tools" at "../lib/tools.xql";

declare namespace xdmp = "http://marklogic.com/xdmp";

let $db   := t:mandatory-field('name')
let $uri  := t:mandatory-field('uri')
let $file := fn:tokenize($uri, '/:')[fn:last()]
return (
   t:query($db, function() { fn:doc($uri) }),
   xdmp:add-response-header('Content-Disposition', 'attachment; filename="' || $file || '"')
)
