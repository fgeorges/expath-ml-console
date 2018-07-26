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
      <status coll="{ $job:status.success }" label="Success"/>
      <status coll="{ $job:status.failure }" label="Failure"/>
   </statuses>/*;

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
      <p><b>TODO</b>: Job ready, let us edit the execution code and start it!</p>,
      v:inline-form('start', (
	 v:input-hidden('id', $id),
	 v:submit('Start job'))),
      <p/>,
      <p/>
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
               <!-- TODO: Display different colors (failure: red, success: green...) and icons -->
	       <td>{ $statuses[@coll eq job:status($task)]/xs:string(@label) }</td>
	       <td>{ v:doc-link('../db/' || $emlc-db || '/', job:uri($task)) }</td>
	    </tr>
      }
      </tbody>
   </table>
};

(:~
 : The overall page function.
 :)
declare function local:page($id as xs:string)
   as element()+
{
   let $job := job:job($id)
   return
      if ( fn:empty($job) ) then
         <wrapper>
	    <!-- TODO: Return a 404. -->
	    <div class="alert alert-danger" role="alert">
	       <span class="glyphicon glyphicon-exclamation-sign" aria-hidden="true"></span>
	       <span class="sr-only">Error:</span>
	       There is no job with ID <code>{ $id }</code>.
	    </div>
	 </wrapper>/*
      else
	 <wrapper>
	    <p>Details of the job with ID <code>{ $id }</code>.</p>
	    <p><b>TODO</b>:</p>
	    <ul>
	       <li>"started", "success" and "failure" job: list tasks and status and messages...</li>
	       <li>"started" job: add also an "interrupt" mecanism?</li>
	    </ul>
            <h3>Properties</h3>
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
		     <td>{ job:lang($job) }</td>
		  </tr>
		  <tr>
		     <!-- TODO: Resolve name. -->
		     <td>Content database</td>
		     <td>{ job:database($job) }</td>
		  </tr>
		  <tr>
		     <!-- TODO: Resolve name. -->
		     <td>Modules database</td>
		     <td>{ job:modules($job) }</td>
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
		     <td>{ job:created($job) }</td>
		  </tr>
	       </tbody>
	    </table>
	    {
	       let $status := job:status($job)
	       return
		  if ( $status eq $job:status.created ) then
		     local:created($job, $id)
		  else
		     local:other($job, $id, $status)
	    }
	 </wrapper>/*
};

v:console-page('../', 'job', 'Job', function() {
   local:page(t:mandatory-field('id'))
})
