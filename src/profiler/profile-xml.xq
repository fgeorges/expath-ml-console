xquery version "3.0";

(:~
 : The profile service, returning an XML report.
 :)

import module namespace t  = "http://expath.org/ns/ml/console/tools"
   at "../lib/tools.xql";

declare namespace prof = "http://marklogic.com/xdmp/profile";

let $query := t:mandatory-field('query')
return
   prof:eval($query)[1]
