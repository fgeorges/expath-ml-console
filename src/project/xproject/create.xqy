xquery version "3.1";

module namespace this = "http://expath.org/ns/ml/console/xproject/create";

import module namespace v = "http://expath.org/ns/ml/console/view" at "../../lib/view.xqy";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare namespace h    = "http://www.w3.org/1999/xhtml";
declare namespace xdmp = "http://marklogic.com/xdmp";
declare namespace map  = "http://marklogic.com/xdmp/map";
declare namespace json = "http://marklogic.com/xdmp/json";

declare function this:page(
   $abbrev  as xs:string,
   $done    as map:map*,
   $error   as map:map?,
   $todo    as map:map*,
   $verbose as xs:boolean?
) as element(h:html)
{
   v:console-page('../../../', 'project', 'Create', function() {
      if ( fn:exists($done) ) then (
         <h3>Success</h3>,
         <p><span style="color: green">✓</span> Project created: { $abbrev }.</p>,
         <p><span style="color: green">→</span> Check/edit files in: <code>{
            $done[1] => map:get('cmd') => map:get('xpdir') }</code>.</p>
      )
      else (
      ),
      if ( fn:exists($error) ) then (
         <h3>Error</h3>,
         <p><span style="color: red">✗</span> Project creation: { $abbrev }.</p>,
         <pre>{ $error => map:get('message') }</pre>,
         if ( $verbose and $error => map:get('error') => map:get('stack') ) then (
            <p>Stacktrace:</p>,
            <pre>{ $error => map:get('error') => map:get('stack') }</pre>
         )
         else (
         )
      )
      else (
      ),
      if ( fn:exists($todo) ) then (
         <h3>Not done</h3>,
         <p><span style="color: yellow">✗</span> Project creation: { $abbrev }.</p>
      )
      else (
      )
   },
   ())
};
