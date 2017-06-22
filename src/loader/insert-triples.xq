xquery version "3.0";

(:~
 : Insert managed triples into a specific database.
 :
 : Accept the following request fields (all mandatory):
 :   - database: the ID of the target database
 :   - file: the file itself, containing the triples
 :   - format: the format of the file (one of those supported by sem:rdf-parse)
 :)

import module namespace t   = "http://expath.org/ns/ml/console/tools" at "../lib/tools.xqy";
import module namespace v   = "http://expath.org/ns/ml/console/view"  at "../lib/view.xql";
import module namespace sem = "http://marklogic.com/semantics"        at "/MarkLogic/semantics.xqy";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare namespace xdmp = "http://marklogic.com/xdmp";

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

let $db     := t:mandatory-field('database')
let $file   := t:mandatory-field('file')
let $format := t:mandatory-field('format')
return
   v:console-page('../', 'tools', 'Tools', function() {
      t:update($db, function() {
         local:page($file, $format)
      })
   })
