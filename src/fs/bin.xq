xquery version "3.0";

import module namespace t = "http://expath.org/ns/ml/console/tools" at "../lib/tools.xqy";

declare namespace xdmp = "http://marklogic.com/xdmp";

let $uri  := t:mandatory-field('uri')
let $file := fn:tokenize($uri, '/:')[fn:last()]
return (
   xdmp:external-binary($uri),
   xdmp:add-response-header('Content-Disposition', 'attachment; filename="' || $file || '"')
)
