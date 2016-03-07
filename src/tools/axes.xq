xquery version "3.0";

import module namespace t = "http://expath.org/ns/ml/console/tools"  at "../lib/tools.xql";
import module namespace v = "http://expath.org/ns/ml/console/view"   at "../lib/view.xql";

declare namespace xdmp = "http://marklogic.com/xdmp";

let $db := t:mandatory-field('database')
let $id := xs:unsignedLong($db)
return
   (: Should anyway call v:console-page(), in order to return a proper HTML page. :)
   v:redirect('../db/' || $id || '/axes')
