xquery version "3.0";

(:~
 : Transform an XML report to a JSON report.
 :)

import module namespace t  = "http://expath.org/ns/ml/console/tools"
   at "../lib/tools.xql";
import module namespace qc = "http://marklogic.com/appservices/qconsole/evaler"
   at "/MarkLogic/appservices/qconsole/qc-evaler.xqy";

declare namespace xdmp = "http://marklogic.com/xdmp";

let $param  := t:mandatory-field('report')
let $report := xdmp:unquote($param)/*
return
   qc:format-report($report)
