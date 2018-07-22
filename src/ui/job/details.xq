xquery version "3.1";

(:~
 : Job details.
 :)

import module namespace t   = "http://expath.org/ns/ml/console/tools"    at "../../lib/tools.xqy";
import module namespace v   = "http://expath.org/ns/ml/console/view"     at "../../lib/view.xqy";
import module namespace job = "http://expath.org/ns/ml/console/job/lib"  at "../../job/job-lib.xqy";

declare default element namespace "http://www.w3.org/1999/xhtml";

(:~
 : The overall page function.
 :)
declare function local:page($id as xs:string)
   as element()+
{
   <wrapper>
      <p>Details of the job <code>{ $id }</code>.</p>
      <p><b>TODO</b>: ...</p>
   </wrapper>/*
};

v:console-page('../', 'job', 'Jobs', function() {
   local:page(t:mandatory-field('id'))
})
