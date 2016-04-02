xquery version "3.0";

(:~
 : Insert managed triples into a specific database.
 :
 : Accept the following request fields (all mandatory):
 :   - database: the ID of the target database
 :   - file: the file itself, containing the triples
 :   - format: the format of the file (one of those supported by sem:rdf-parse)
 :)

import module namespace a   = "http://expath.org/ns/ml/console/admin" at "../lib/admin.xql";
import module namespace t   = "http://expath.org/ns/ml/console/tools" at "../lib/tools.xql";
import module namespace v   = "http://expath.org/ns/ml/console/view"  at "../lib/view.xql";
import module namespace sem = "http://marklogic.com/semantics"        at "/MarkLogic/semantics.xqy";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare namespace map  = "http://marklogic.com/xdmp/map";
declare namespace xdmp = "http://marklogic.com/xdmp";

declare option xdmp:update "true";

(:~
 : The overall page function.
 :)
declare function local:page($file, $format as xs:string)
   as element()+
{
   <p>Triples succesfully inserted as "{ $format }", in the following files:</p>,
   <ul> {
      sem:rdf-insert(
         sem:rdf-parse(
            xdmp:binary-decode($file, 'UTF-8'),
            $format))
         ! <li>{ . }</li>
   }
   </ul>,
   <p>Back to <a href="../loader">document manager</a>.</p>
};

let $db     := xs:unsignedLong(t:mandatory-field('database'))
let $file   := t:mandatory-field('file')
let $format := t:mandatory-field('format')
let $params := 
      map:new((
         map:entry('file',   $file),
         map:entry('format', $format),
         map:entry('fun',    local:page#2)))
return
   v:console-page(
      '../',
      'tools',
      'Tools',
      function() {
         a:eval-on-database(
            $db,
            'declare namespace xdmp = "http://marklogic.com/xdmp";
             declare option xdmp:update "true";
             declare variable $file   external;
             declare variable $format external;
             declare variable $fun    external;
             $fun($file, $format)',
            $params)
      })
