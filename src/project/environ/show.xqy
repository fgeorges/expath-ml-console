xquery version "3.0";

module namespace this = "http://expath.org/ns/ml/console/environ/show";

import module namespace v = "http://expath.org/ns/ml/console/view" at "../../lib/view.xql";

declare namespace json = "http://marklogic.com/xdmp/json";

declare function this:page($name as xs:string, $elems)
{
   v:console-page('../../../../', 'project', 'Environ ' || $name, function() {
      json:array-values($elems)
   })
};
