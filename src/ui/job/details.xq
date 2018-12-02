xquery version "3.1";

(:~
 : Job details.
 :)

import module namespace t   = "http://expath.org/ns/ml/console/tools"   at "../../lib/tools.xqy";
import module namespace v   = "http://expath.org/ns/ml/console/view"    at "../../lib/view.xqy";
import module namespace job = "http://expath.org/ns/ml/console/job/lib" at "../../job/job-lib.xqy";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare namespace xdmp = "http://marklogic.com/xdmp";

declare variable $emlc-db  := xdmp:database-name(xdmp:database());
declare variable $statuses :=
   <statuses>
      <status coll="{ $job:status.created }" label="Created"/>
      <status coll="{ $job:status.ready   }" label="Ready"/>
      <status coll="{ $job:status.started }" label="Started"/>
      <status coll="{ $job:status.success }" label="Success" style="color: green;"/>
      <status coll="{ $job:status.failure }" label="Failure" style="color: red;"/>
   </statuses>/*;

(:~
 : Resolve a database ID.
 :)
declare function local:db-link($db)
   as element()
{
   xdmp:database-name(xs:unsignedLong($db))
   ! v:db-link('../' || ., .)
};

(:~
 : The page for jobs "created".
 :)
declare function local:created($job as node(), $id as xs:string)
   as element()+
{
   <h3>Initialize</h3>,
   <p>The job has been properly created.</p>,
   <p>To create its tasks, edit the code in the init module above, to return the
      task chuncks.</p>,
   <p>When ready, click on the button to create the tasks.</p>,
   v:inline-form('init', (
      v:input-hidden('id', $id),
      v:submit('Init tasks')))
};

(:~
 : The page for jobs other than "created".
 :)
declare function local:other($job as node(), $id as xs:string, $status as xs:string)
   as element()+
{
   if ( $status eq $job:status.ready ) then (
      <h3>Start</h3>,
      <p>Job ready, make sure you edited the execution code, and start it!</p>,
      v:inline-form('start', (
	 v:input-hidden('id', $id),
	 v:submit('Start job'))),
      <p style="margin-bottom: 3em"/>
   )
   else
      (),
   <h3>Tasks</h3>,
   <table class="table prof-datatable">
      <thead>
	 <tr>
	    <th>Order</th>
	    <th>ID</th>
	    <th>Status</th>
	    <th>URI</th>
	 </tr>
      </thead>
      <tbody> {
         for $task  in job:tasks($job)
         let $order := job:order($task)
         order by xs:integer($order)
	 return
	    <tr>
	       <td>{ $order }</td>
	       <td><code>{ job:id($task) }</code></td>
	       <td>{ $statuses[@coll eq $status]!xs:string(@label) }</td>
	       <td>{ v:doc-link('../db/' || $emlc-db || '/', job:uri($task)) }</td>
	    </tr>
      }
      </tbody>
   </table>
};

(:~
 : The overall page function.
 :)
declare function local:page($job as node(), $id as xs:string, $name as xs:string?)
   as element()+
{
   let $status := job:status($job)
   return
      <wrapper>
	 <p>Details of the job with ID <code>{ $id }</code>.</p>
	 <table class="table prof-datatable">
	    <thead>
	       <tr>
		  <th>Property</th>
		  <th>Value</th>
	       </tr>
	    </thead>
	    <tbody>
	       <tr>
		  <td>Name</td>
		  <td>{ job:name($job) }</td>
	       </tr>
	       <tr>
		  <td>Description</td>
		  <td>{ job:desc($job) }</td>
	       </tr>
	       <tr>
		  <td>URI</td>
		  <td>{ v:doc-link('../db/' || $emlc-db || '/', job:uri($job)) }</td>
	       </tr>
	       <tr>
		  <td>Collection</td>
		  <td>{ v:coll-link('../db/' || $emlc-db || '/', job:collection($job)) }</td>
	       </tr>
	       <tr>
		  <td>Language</td>
		  <td>{ if ( job:lang($job) eq 'sjs' ) then 'JavaScript' else 'XQuery' }</td>
	       </tr>
	       <tr>
		  <td>Content database</td>
		  <td>{ job:database($job) ! local:db-link(.) }</td>
	       </tr>
	       <tr>
		  <td>Modules database</td>
		  <td>{ job:modules($job) ! local:db-link(.) }</td>
	       </tr>
	       <tr>
		  <td>Task init module</td>
		  <td>{ v:doc-link('../db/' || $emlc-db || '/', job:init-module($job)) }</td>
	       </tr>
	       <tr>
		  <td>Task execution module</td>
		  <td>{ v:doc-link('../db/' || $emlc-db || '/', job:exec-module($job)) }</td>
	       </tr>
	       <tr>
		  <td>Created</td>
		  <td> {
		     let $c := job:created($job) ! xs:string(.)
		     return
			fn:substring($c, 1, 10)
			|| ', at '
			|| fn:substring($c, 12, 8)
		  }
		  </td>
	       </tr>
	       <tr>
		  <td>Status</td>
	          <td>{ $statuses[@coll eq $status]!string(@label) }</td>
	       </tr>
	    </tbody>
	 </table>
	 {
	    job:error($job) ! <div class="alert alert-danger" role="alert">
	       <span class="fa fa-exclamation-circle" aria-hidden="true"></span>
	       <span class="sr-only">Error:</span>
	       <span>{ . }</span>
	    </div>,
	    if ( $status eq $job:status.created ) then
	       local:created($job, $id)
	    else
	       local:other($job, $id, $status)
	 }
      </wrapper>/*
};

let $id    := t:mandatory-field('id')
let $job   := job:job($id)
let $name  := $job ! job:name(.)
let $title := ($name ! ('Job - ' || .), 'Job')[1]
return
   v:console-page('../', 'job', $title, function() {
      if ( fn:empty($job) ) then
	 <div class="alert alert-danger" role="alert">
	    <span class="fa fa-exclamation-circle" aria-hidden="true"></span>
	    <span class="sr-only">Error:</span>
	    There is no job with ID <code>{ $id }</code>.
	 </div>
      else
         local:page($job, $id, $name)
   })
