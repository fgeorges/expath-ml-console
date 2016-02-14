xquery version "3.0";

(:~
 : Convert triples to a sem:triples document.
 :
 : Accept the following request fields (all mandatory):
 :   - file: the file itself
 :   - format: the format of the triple file (one of those accepted by sem:rdf-parse)
 :)

import module namespace bin = "http://expath.org/ns/ml/console/binary" at "../lib/binary.xql";
import module namespace t   = "http://expath.org/ns/ml/console/tools"  at "../lib/tools.xql";
import module namespace sem = "http://marklogic.com/semantics"         at "/MarkLogic/semantics.xqy";

declare namespace xdmp = "http://marklogic.com/xdmp";

declare variable $extensions :=
   <exts>
      <ext format="triplexml" kind="xml">xml</ext>
      <ext format="ntriple"   kind="text">nt</ext>
      <ext format="nquad"     kind="text">nq</ext>
      <ext format="turtle"    kind="text">ttl</ext>
      <ext format="rdfxml"    kind="xml">rdf.xml</ext>
      <ext format="n3"        kind="text">n3</ext>
      <ext format="trig"      kind="text">trig</ext>
      <ext format="rdfjson"   kind="text">json</ext>
   </exts>;

(:~
 : Decode binary to text, using `charset` from Content-Type, or `UTF-8` by default.
 :)
declare function local:decode-binary(
   $doc    as node(), (: binary() :)
   $ctype  as xs:string?
) as xs:string
{
   let $parsed  := $ctype ! t:parse-content-type(.)
   let $charset := ( $parsed/param[@name eq 'charset'], 'UTF-8' )[1]
   return
      xdmp:binary-decode($doc, $charset)
};

(:~
 : Return the input as text (might need to decode binary to text).
 :)
declare function local:get-text(
   $doc    as node(), (: document-node() | binary() :)
   $ctype  as xs:string?
) as item() (: xs:string | document-node(text()) :)
{
   if ( bin:is-binary($doc) ) then
      local:decode-binary($doc, $ctype)
   else
      $doc
};

(:~
 : Return the input as XML (might need to parse text, and maybe to decode binary to text).
 :)
declare function local:get-xml(
   $doc    as node(), (: document-node() | binary() :)
   $ctype  as xs:string?
) as item() (: xs:string | document-node(text()) :)
{
   if ( bin:is-binary($doc) ) then
      xdmp:unquote(local:decode-binary($doc, $ctype))
   else if ( fn:exists($doc/text()) and fn:empty($doc/node()[2]) ) then
      xdmp:unquote($doc)
   else
      $doc
};

(:~
 : Return the input in the correct format, depending on $kind.
 :)
declare function local:get-input(
   $doc    as node(), (: document-node() | binary() :)
   $format as xs:string,
   $kind   as xs:string,
   $ctype  as xs:string?
) as item()
{
   if ( $kind eq 'text' ) then
      local:get-text($doc, $ctype)
   else if ( $kind eq 'xml' ) then
      local:get-xml($doc, $ctype)
   else
      t:error('invalid-format', 'Invalid triple file format: ' || $kind)
};

let $file     := t:mandatory-field('file')
let $input    := t:mandatory-field('input')
let $output   := t:mandatory-field('output')
let $filename := t:optional-field-filename('file', ())
let $ctype    := t:optional-field-content-type('file', ())
let $kind     := $extensions/ext[@format eq $input]/@kind
let $ext      := $extensions/ext[@format eq $output]
let $content  := local:get-input($file, $input, $kind, $ctype)
(: must be evaluated before setting the response content disposition,
   or errors might be "silently ignored" (there is no error representation
   in, say, Turle) :)
let $result   := sem:rdf-serialize(sem:rdf-parse($content, $input), $output)
return (
   xdmp:add-response-header(
      'Content-Disposition', 'attachment; filename="'
      || ( $filename ! fn:replace($filename, '\.[^.]+$', '.'), 'triples.' )[1]
      || $ext || '"'),
   $result
)
