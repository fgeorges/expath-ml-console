xquery version "3.0";

(:~
 : The job page.
 :
 : TODO: Endpoints to support this page (and beyond):
 :
 : - POST /api/job/create            -- create and save the job and all its tasks
 : - POST /api/job/create?test=true  -- return the job and its first task, no save
 : - POST /api/job/xxx/run           -- run the job xxx
 :)

import module namespace a = "http://expath.org/ns/ml/console/admin" at "../lib/admin.xqy";
import module namespace v = "http://expath.org/ns/ml/console/view"  at "../lib/view.xqy";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare namespace xdmp = "http://marklogic.com/xdmp";

declare variable $appservers := a:get-appservers()/a:appserver;

declare variable $sample-create-xqy :=
'
(: This is a job creation query.
 : Replace this buffer with your own query.
 :)

xquery version "3.1";

(''001'', ''002'', ''003'')
';

declare variable $sample-create-sjs :=
'
// This is a job creation script.
// Replace this buffer with your own script.

"use strict";

[''001'', ''002'', ''003''];
';

declare variable $sample-task-xqy :=
'
(: TODO: ...
 :)

xquery version "3.1";

declare namespace xdmp = "http://marklogic.com/xdmp";

xdmp:log("Bla bla bla")
';

declare variable $sample-task-sjs :=
'
// TODO: ...

"use strict";

console.log("Bla bla bla");
';

(:~
 : The overall page function.
 :)
declare function local:page()
   as element()+
{
   <wrapper>
      <p>Bla bla bla...</p>
      <p><b>TODO</b>: Allow to switch between XQuery and JavaScript (or at least
         to send XQuery by changing the hard-coded default.)</p>
      <p>Then try the creation phase (and runtime?) by chuncking all URIs in, say,
         "Documents".</p>
      <p>Bla bla bla...</p>

      <h3>Setup</h3>
      <label class="radio-inline">
	 <input type="radio" name="lang" id="lang-xqy" value="xqy"/> XQuery
      </label>
      <label class="radio-inline">
	 <input type="radio" name="lang" id="lang-sjs" value="sjs" checked="checked"/> JavaScript
      </label>
      <p/>
      <div class="row">
         <div class="col-sm-12">
            <div class="btn-group">
               <button type="button" class="btn btn-default dropdown-toggle"
                       data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">
                  Databases <span class="caret"/>
               </button>
               <ul class="dropdown-menu" style="min-width: 400pt"> {
                  for $db in a:get-databases()/a:database
                  order by $db/a:name
                  return
                     local:format-db($db, 'target-id', 'target-label')
               }
               </ul>
            </div>
            <div class="btn-group" style="margin-left: 10px;">
               <button type="button" class="btn btn-default dropdown-toggle"
                       data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">
                  HTTP servers <span class="caret"/>
               </button>
               <ul class="dropdown-menu" style="min-width: 400pt"> {
		  local:format-asses('http')
               }
               </ul>
            </div>
            <div class="btn-group" style="margin-left: 10px;">
               <button type="button" class="btn btn-default dropdown-toggle"
                       data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">
                  XDBC servers <span class="caret"/>
               </button>
               <ul class="dropdown-menu" style="min-width: 400pt"> {
		  local:format-asses('xdbc')
               }
               </ul>
            </div>
            <div class="btn-group" style="margin-left: 10px;">
               <button type="button" class="btn btn-default dropdown-toggle"
                       data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">
                  ODBC servers <span class="caret"/>
               </button>
               <ul class="dropdown-menu" style="min-width: 400pt"> {
		  local:format-asses('odbc')
               }
               </ul>
            </div>
            <div class="btn-group" style="margin-left: 10px;">
               <button type="button" class="btn btn-default dropdown-toggle"
                       data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">
                  WebDAV servers <span class="caret"/>
               </button>
               <ul class="dropdown-menu" style="min-width: 400pt"> {
		  local:format-asses('webDAV')
               }
               </ul>
            </div>
            <div class="btn-group pull-right active" role="group">
               <button id="target-label" type="button" class="btn btn-danger" disabled="disabled">select a source</button>
            </div>
            <div id="target-id" style="display: none"/>
         </div>
      </div>

      <h3>Create job</h3>
      <!-- TODO: How to change dynamically the language of the editor, depending
	   on the value of the "lang" radio buttons?  And its content to
           $sample-create-xqy? -->
      { v:edit-text(text { $sample-create-sjs }, 'javascript', 'create-code') }

      <div class="row">
         <div class="col-sm-3">
            <button id="go-profile"
                    class="btn btn-default"
                    onclick="jobCreate('create-code', 'create-detail', 'total-time', 'tasks-count', 'job-uri', 'job-coll', 'create-dry');">Create</button>
	    <div class="checkbox">
	       <label>
		  <input type="checkbox" value="" checked="checked" id="create-dry"/> Dry mode
	       </label>
	    </div>
         </div>
      </div>

      <div class="create-success" style="display: none">
	 <h3>Created job</h3>
	 <p>
	    Total time: <span id="total-time"/>
	 </p>
	 <p>
	    Number of tasks created: <span id="tasks-count"/>
	 </p>
	 {
	    let $db := xdmp:database-name(xdmp:database())
	    return (
	       <p>
		  <span>Job URI: </span>
		  <a data-href="db/{ $db }/doc?uri=">
		     <code class="doc" id="job-uri"/>
		  </a>
	       </p>,
	       <p>
		  <span>Collection: </span>
		  <a data-href="db/{ $db }/coll?uri=">
		     <code class="coll" id="job-coll"/>
		  </a>
	       </p>
	    )
	 }
	 <table class="table table-bordered prof-datatable" id="create-detail" data-order-on="1">
	    <thead>
	       <tr>
		  <th>Number</th>
		  <th>Created</th>
		  <th>Label</th>
		  <th>URI</th>
	       </tr>
	    </thead>
	    <tbody/>
	 </table>
      </div>

      <h3>Task code</h3>
      <!-- TODO: How to change dynamically the language of the editor, depending
	   on the value of the "lang" radio buttons?  And its content to
           $sample-task-xqy? -->
      { v:edit-text(text { $sample-task-sjs }, 'javascript', 'task-code') }

      <!-- TODO: Disable the buttons (test create, run job, etc.) until a source has
	   been selected.  Look at the profiler to see how it is done there. -->
      <div class="row">
         <div class="col-sm-3">
            <button id="run-job"
                    class="btn btn-default"
                    onclick="alert('TODO: Still to implement creating and launching the job.') // runJob('create-code', 'task-code', 'create-detail', 'total-time', 'tasks-count', 'job-uri', 'job-coll');">Run job</button>
            <button id="test-task"
                    class="btn btn-default"
                    onclick="alert('TODO: Still to implement a way to test a single task, live.');"
                    style="margin-left: 10px;">Test task</button>
         </div>
      </div>
   </wrapper>/*
};

declare function local:format-db(
   $db           as element(a:database),
   $target-id    as xs:string,
   $target-label as xs:string
) as element(li)
{
   <li>
      <a onclick='selectTarget("{ $target-id }", "{ $db/@id }", "{ $target-label }", "{ $db/a:name }");'> {
         $db/fn:string(a:name)
      }
      </a>
   </li>
};

declare function local:format-asses($type as xs:string)
{
   let $asses := $appservers[@type eq $type]
   return
      if ( fn:exists($asses) ) then
         for $as in $asses
         order by $as/a:name
         return
            local:format-as($as, 'target-id', 'target-label')
      else
         <li><a style="font-style: italic">(none)</a></li>
};

declare function local:format-as(
   $as           as element(a:appserver),
   $target-id    as xs:string,
   $target-label as xs:string
) as element(li)
{
   let $types :=
         <types>
            <type code="http"   label="HTTP"/>
            <type code="xdbc"   label="XDBC"/>
            <type code="odbc"   label="ODBC"/>
            <type code="webDAV" label="WebDAV"/>
         </types>/*
   let $name  := xs:string($as/a:name)
   let $label := $name || ' (' || $types[@code eq $as/@type]/@label || ')'
   return
      <li>
         <a onclick='selectTarget("{ $target-id }", "{ $as/@id }", "{ $target-label }", "{ $label }");'>
            <span> {
               $name
            }
            </span>
            <br/>
            <small> {
               '          Content: ' || $as/a:db
            }
            </small>
            <br/>
            <small> {
               '          Modules: '
                  || ( $as/a:modules-db, 'file' )[1]
                  || ' &lt;'
                  || $as/a:root
                  || '>'
            }
            </small>
         </a>
      </li>
};

v:console-page('../', 'job', 'Jobs', local:page#0)
