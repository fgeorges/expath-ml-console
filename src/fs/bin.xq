xquery version "3.0";

import module namespace t = "http://expath.org/ns/ml/console/tools" at "../lib/tools.xql";

declare namespace xdmp = "http://marklogic.com/xdmp";

let $uri := t:mandatory-field('uri')
return
   xdmp:external-binary($uri)
