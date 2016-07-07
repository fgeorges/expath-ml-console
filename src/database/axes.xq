xquery version "3.0";

import module namespace t = "http://expath.org/ns/ml/console/tools"  at "../lib/tools.xql";
import module namespace v = "http://expath.org/ns/ml/console/view"   at "../lib/view.xql";

import module namespace tmp = "http://marklogic.com/xdmp/temporal" 
   at "/MarkLogic/temporal.xqy";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare function local:page()
{
   <p>Here are the temporal axes on this database:</p>,
   let $axes := tmp:axes()
   return
      if ( fn:empty($axes) ) then
         <p><em>There is no temporal axis on this database.</em></p>
      else
         <ul> {
            $axes ! <li>{ . }</li>
         }
         </ul>,
   <p>Here are the temporal collections on this database:</p>,
   let $colls := tmp:collections()
   return
      if ( fn:empty($colls) ) then
         <p><em>There is no temporal collection on this database.</em></p>
      else
         <ul> {
            for $c in $colls
            let $v := tmp:collection-get-axis($c, 'valid')
            let $s := tmp:collection-get-axis($c, 'system')
            let $o := fn:string-join(tmp:collection-get-options($c), ', ')
            return
               <li>{ $c } ({ $v } / { $s } / { $o })</li>
         }
         </ul>
};

let $db := t:mandatory-field('database')
return
   v:console-page('../../', 'tools', 'Temporal', function() {
      t:query($db, local:page#0)
   })
