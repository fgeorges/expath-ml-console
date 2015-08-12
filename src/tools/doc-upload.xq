xquery version "3.0";

(:~
 : The document upload endpoint.
 :
 : TODO: Use a Javascript endpoint, as the goal is to return JSON...
 :)

import module namespace a = "http://expath.org/ns/ml/console/admin" at "../lib/admin.xql";
import module namespace v = "http://expath.org/ns/ml/console/view"  at "../lib/view.xql";

declare namespace xdmp = "http://marklogic.com/xdmp";

(:
xdmp:set-response-content-type('application/json')
,
fn:error((),
     '&#10;Filename: ' || xdmp:get-request-field-filename('file')
  || '&#10;User:     ' || xdmp:get-request-user()
  || '&#10;Username: ' || xdmp:get-request-username()
  || '&#10;User:     ' || xdmp:get-current-user()
  || '&#10;User ID:  ' || xdmp:get-current-userid()!xs:string(.))
,
'
  {"files": [
    {
      "name": "NOTES.txt",
      "size": 123,
      "error": "Filetype not allowed"
    }
  ]}
'

var bodies = xdmp.getRequestField('files');
:)

declare function local:type($n as node()) as xs:string
{
   if ( $n instance of text() ) then
      'text'
   else if ( $n instance of element() ) then
      'element'
   else if ( $n instance of document-node() ) then
      'document'
   else if ( $n instance of attribute() ) then
      'attribute'
   else if ( $n instance of comment() ) then
      'comment'
   else if ( $n instance of processing-instruction() ) then
      'pi'
   else
      'binary'
};

let $bodies := xdmp:get-request-field('files')
for $n at $p in xdmp:get-request-field-filename('files')
return
   <file name="{ $n }" pos="{ $p }" type="{ local:type($bodies[$p]) }"/>
