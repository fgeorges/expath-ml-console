xquery version "3.0";

(:~
 : The profile service.
 :)

import module namespace t  = "http://expath.org/ns/ml/console/tools"
   at "../lib/tools.xql";
import module namespace qc = "http://marklogic.com/appservices/qconsole/evaler"
   at "/MarkLogic/appservices/qconsole/qc-evaler.xqy";

declare namespace prof = "http://marklogic.com/xdmp/profile";

let $query  := t:mandatory-field('query')
let $report := prof:eval($query)[1]
return
   qc:format-report($report)
