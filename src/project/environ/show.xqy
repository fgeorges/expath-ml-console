xquery version "3.0";

(: TODO: Factorize this script with setup.xqy. :)

module namespace this = "http://expath.org/ns/ml/console/environ/show";

import module namespace v = "http://expath.org/ns/ml/console/view" at "../../lib/view.xqy";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare namespace xdmp = "http://marklogic.com/xdmp";
declare namespace json = "http://marklogic.com/xdmp/json";
declare namespace map  = "http://marklogic.com/xdmp/map";

declare function this:error(
   $environ as xs:string,
   $project as xs:string,
   $err     as item((: map:map :))
)
{
   v:console-page('../../../../', 'project', 'Environ ' || $environ, function() {
      let $code   := map:get($err, 'name')
      let $data   := map:get($err, 'data')
      let $msg    := map:get($err, 'message')
      let $stack  := map:get($err, 'stack')
      let $action := map:get($err, 'action')
      let $error  := map:get($err, 'error')
      return
         if ( fn:exists($action) ) then (
            <p><b>Error</b>: Unexpected error: <code>{ $action }</code>, <code>{ $msg }</code>.</p>,
            <p>Please report this as an
               <a href="https://github.com/fgeorges/expath-ml-console">issue on Githib</a>.</p>,
            <pre>{ $error }</pre>
         )
         else if ( $code eq 'SVC-SOCHN' ) then (
            <p><b>Error</b>: Unknown host: <code>{ json:array-values($data)[2] }</code>.</p>,
            <p>Check your environment file.</p>
         )
         else if ( fn:exists($msg) ) then (
            <p><b>Error</b>: Unknown error: { $msg }.</p>,
            <p>Please report this as an
               <a href="https://github.com/fgeorges/expath-ml-console">issue on Githib</a>.</p>,
            <pre>{ $stack }</pre>
         )
         else (
            <p><b>Error</b>: Unknown error.</p>,
            <p>Please report this as an
               <a href="https://github.com/fgeorges/expath-ml-console">issue on Githib</a>.</p>,
            <pre>{ xdmp:quote($err) }</pre>
         )
   })
};

declare function this:page(
   $environ as xs:string,
   $project as xs:string,
   $elems   as item((: json:array :))
)
{
   v:console-page('../../../../', 'project', 'Environ ' || $environ, function() {
      <p>Details of the environment <code>{ $environ }</code>, in project
         { v:proj-link('../../../' || $project, $project) }.</p>,
      json:array-values($elems)
   })
};
