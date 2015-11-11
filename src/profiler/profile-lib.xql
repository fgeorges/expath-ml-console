xquery version "3.0";

(:~
 : The profile library.
 :)
module namespace p = "http://expath.org/ns/ml/console/profile";

import module namespace a       = "http://expath.org/ns/ml/console/admin"
   at "../lib/admin.xql";
import module namespace t       = "http://expath.org/ns/ml/console/tools"
   at "../lib/tools.xql";
import module namespace qc-eval = "http://marklogic.com/appservices/qconsole/evaler"
   at "/MarkLogic/appservices/qconsole/qc-evaler.xqy";
import module namespace qc-amp  = "http://marklogic.com/appservices/qconsole/util-amped"
   at "/MarkLogic/appservices/qconsole/qconsole-amped.xqy";

declare namespace prof = "http://marklogic.com/xdmp/profile";


declare namespace json = "http://marklogic.com/xdmp/json";
declare namespace xdmp = "http://marklogic.com/xdmp";


declare function p:profile($query as xs:string, $target as xs:string)
   as element(prof:report)
{
   if ( $target castable as xs:unsignedLong ) then
      let $id      := xs:unsignedLong($target)
      let $thing   := a:get-appserver-or-database($id)
      let $options := 
            if ( fn:empty($thing) ) then
               t:error('invalid-id', 'No DB or AS with the ID: ' || $target)
            else if ( $thing[self::a:database] ) then
               qc-amp:qconsole-get-eval-options((), $id, fn:true())
            else
               qc-amp:qconsole-get-eval-options($id, (), fn:true())
      return
         prof:eval($query, (), $options)[1]
   else
      t:error('invalid-id', 'Invalid DB or AS ID: ' || $target)
};

declare function p:to-json($report as element(prof:report))
   as json:object
{
   qc-eval:format-report($report)
};
