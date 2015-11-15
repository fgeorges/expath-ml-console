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
import module namespace json    = "http://marklogic.com/xdmp/json"
   at "/MarkLogic/json/json.xqy";

declare namespace eval  = "xdmp:eval";
declare namespace prof  = "http://marklogic.com/xdmp/profile";
declare namespace map   = "http://marklogic.com/xdmp/map";
declare namespace err   = "http://www.w3.org/2005/xqt-errors";
declare namespace error = "http://marklogic.com/xdmp/error";

declare function p:profile($query as xs:string, $target as xs:string, $format as xs:string)
   as item()
{
   if ( $target castable as xs:unsignedLong ) then
      let $id      := xs:unsignedLong($target)
      let $thing   := a:get-appserver-or-database($id)
      let $db      := $id[$thing[self::a:database]]
      let $mod     := $thing[self::a:appserver]/( a:modules-db/@id, 0[$thing/a:modules-path] )
      let $options := 
            if ( fn:empty($thing) ) then
               t:error('invalid-id', 'No DB or AS with the ID: ' || $target)
            else if ( $thing[self::a:database] ) then
               qc-amp:qconsole-get-eval-options((), $id, fn:true())
            else
               qc-amp:qconsole-get-eval-options($id, (), fn:true())
      return
         try {
            p:format-report(
               prof:eval($query, (), $options)[1],
               $format)
         }
         catch * {
            p:format-error($err:additional, $options, $query, $format)
         }
   else
      t:error('invalid-id', 'Invalid DB or AS ID: ' || $target)
};

declare %private function p:format-report($report as element(prof:report), $format as xs:string)
   as item()
{
   switch ( $format )
      case 'xml'  return $report
      case 'json' return qc-eval:format-report($report)
      default     return t:error('invalid-format', 'Invalid format: ' || $format)
};

declare %private variable $p:json-config :=
   let $config := json:config('custom')
   return (
      map:put($config, 'array-element-names', ('stack', 'code', 'lines')),
      $config
   );

declare %private function p:format-error(
   $error   as element(error:error),
   $options as element(eval:options),
   $query   as xs:string,
   $format  as xs:string
) as item()
{
   let $err := qc-eval:interpret-eval-error(
                  xs:unsignedLong($options/eval:database),
                  xs:unsignedLong($options/eval:modules),
                  $options/eval:root,
                  $error,
                  $query)
   return
      switch ( $format )
         case 'xml'  return $err
         case 'json' return json:transform-to-json-string($err, $p:json-config)
         default     return t:error('invalid-format', 'Invalid format: ' || $format)
};
