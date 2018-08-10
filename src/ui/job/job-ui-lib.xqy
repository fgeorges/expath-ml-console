xquery version "3.1";

(:~
 : Library for the job UI.
 :)

module namespace this = "http://expath.org/ns/ml/console/job/ui";

import module namespace job = "http://expath.org/ns/ml/console/job/lib" at "../../job/job-lib.xqy";

declare default element namespace "http://www.w3.org/1999/xhtml";

(: Return something like "42 jobs".
 :)
declare function this:count($count)
   as node()+
{
   if ( $count eq 0 ) then
      <w><b>no</b> job</w>/node()
   else if ( $count eq 1 ) then
      <w><b>1</b> job</w>/node()
   else
      <w><b>{ $count }</b> jobs</w>/node()
};

(: The overall page function for a "status" page.
 :)
declare function this:status-page($jobs as node()*, $count as xs:integer)
   as element()+
{
   <wrapper>
      <p>There are { this:count($count) } with status <code>ready</code>.</p>
      <table class="table prof-datatable" data-order-on="-3">
	 <thead>
	    <tr>
	       <th>ID</th>
	       <th>Name</th>
	       <th>Created</th>
	    </tr>
	 </thead>
	 <tbody> {
	    for $job  in $jobs
	    let $id   := job:id($job)
	    let $name := job:name($job)
	    let $time := job:created($job)
	    order by $time
	    return
               <tr>
	          <td><a href="{ $id }"><code>{ $id }</code></a></td>
	          <td>{ $name }</td>
	          <td>{ $time }</td>
               </tr>
         }
	 </tbody>
      </table>
   </wrapper>/*
};
