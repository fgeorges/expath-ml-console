xquery version "3.0";

(:~
 : Convert triples to a sem:triples document.
 :
 : Accept the following request fields (all mandatory):
 :   - file: the file itself
 :   - format: the format of the triple file (one of those accepted by sem:rdf-parse)
 :)

import module namespace t   = "http://expath.org/ns/ml/console/tools" at "../lib/tools.xql";
import module namespace sem = "http://marklogic.com/semantics" at "/MarkLogic/semantics.xqy";

declare namespace xdmp = "http://marklogic.com/xdmp";

declare variable $extensions :=
   <exts>
      <ext format="triplexml">xml</ext>
      <ext format="ntriple">???</ext>
      <ext format="nquad">???</ext>
      <ext format="turtle">ttl</ext>
      <ext format="rdfxml">xml</ext>
      <ext format="n3">???</ext>
      <ext format="trig">???</ext>
      <ext format="rdfjson">json</ext>
   </exts>;

let $file   := t:mandatory-field('file')
let $input  := t:mandatory-field('input')
let $output := t:mandatory-field('output')
let $ext    := xs:string($extensions/ext[@format eq $output])
return (
   (: TODO: If the name of the input file is known, use it to generate a more
      meaningful name.  If not, stick to triples.*. :)
   xdmp:add-response-header('Content-Disposition', 'attachment; filename="triples.' || $ext || '"'),
   sem:rdf-serialize(
      sem:rdf-parse(
         xdmp:binary-decode($file, 'UTF-8'),
         $input),
      $output)
)
