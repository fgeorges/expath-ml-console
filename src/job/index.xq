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
'(: This is a job creation query.
 : Replace this buffer with your own query.
 :)

xquery version "3.1";

declare namespace cts = "http://marklogic.com/cts";

declare variable $size := 10;

declare function local:uris($uris as xs:string*) as element(uris)* {
    if ( fn:empty($uris) ) then (
    )
    else (
        <uris> {
            $uris[position() le $size] ! <uri>{ . }</uri>
        }
        </uris>,
        local:uris($uris[position() gt $size])
    )
};

local:uris(cts:uris())
';

declare variable $sample-create-sjs :=
'// This is a job creation script.
// Replace this buffer with your own script.

"use strict";

[''001'', ''002'', ''003''];
';

declare variable $sample-task-xqy :=
'
(: TODO: ...
 :)

xquery version "3.1";

declare namespace c    = "http://expath.org/ml/console";
declare namespace xdmp = "http://marklogic.com/xdmp";

declare variable $task as element(c:task) external;

xdmp:log("TODO: Run job: " || $task/c:id)
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
      <div style="display: none">
	 <p id="sample-create-xqy">{ $sample-create-xqy }</p>
	 <p id="sample-create-sjs">{ $sample-create-sjs }</p>
	 <p id="sample-task-xqy">{ $sample-task-xqy }</p>
	 <p id="sample-task-sjs">{ $sample-task-sjs }</p>
      </div>

      <p><b>TODO</b>: Implement "Run job", based on the URI of the job currently
         listed.</p>
      <p>Then redesign the whole job area (index with list/search for jobs/form
         to create a new job, page to display one job/run it/list its tasks with
         their status, etc.)</p>
      <p>Allow for saving the creation code, and task code, maybe reusing the
         editor in the document view page (in the browser area.)</p>
      <p>So lifecycle in the UI: create job, link the job to a new module doc,
         which can be edited online, init tasks, (re)view their list, create/edit
         the module to exec a task, run job.</p>
      <p>So lifecycle through API: create job, init tasks providing init code, run
         job providing task exec code.</p>

      <h3>Setup</h3>
      <label class="radio-inline">
	 <input type="radio" name="lang" id="lang-xqy" value="xqy" checked="checked"/> XQuery
      </label>
      <label class="radio-inline">
	 <input type="radio" name="lang" id="lang-sjs" value="sjs"/> JavaScript
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
      { v:edit-text(text { $sample-create-xqy }, 'xquery', 'create-code') }

      <div class="row">
         <div class="col-sm-3">
            <button id="go-profile"
                    class="btn btn-default need-target"
                    disabled="disabled"
                    onclick="create();">Create</button>
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
      { v:edit-text(text { $sample-task-xqy }, 'xquery', 'task-code') }

      <!-- TODO: Disable the buttons (test create, run job, etc.) until a source has
	   been selected.  Look at the profiler to see how it is done there. -->
      <div class="row">
         <div class="col-sm-3">
            <button id="run-job"
                    class="btn btn-default need-job"
                    disabled="disabled"
                    onclick="run();">Run job</button>
            <button id="test-task"
                    class="btn btn-default need-job"
                    disabled="disabled"
                    onclick="testTask();"
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

v:console-page('../', 'job', 'Jobs', local:page#0,
   <script>
      $('input[type=radio][name=lang]').change(function() {{
         switchLang(this.value);
      }});

      function switchLang(lang) {{
         var mode = lang === 'sjs'
            ? 'ace/mode/javascript'
            : 'ace/mode/xquery';
         switchEditor('create', lang, mode);
         switchEditor('task',   lang, mode);
      }}

      function switchEditor(which, lang, mode) {{
         editors[which + '-code']
            .editor
            .setSession(
	       ace.createEditSession(
                  $('#sample-' + which + '-' + lang).text(),
                  mode));
      }}

      function create() {{
	 jobCreate('create-code', 'create-detail', 'total-time', 'tasks-count', 'job-uri', 'job-coll', 'create-dry');
         $('.need-job').prop('disabled', false);
      }}

      function run() {{
         jobRun('create-code', 'task-code', 'create-detail', 'total-time', 'tasks-count', 'job-uri', 'job-coll');
      }}

      function testTask() {{
         alert('TODO: Still to implement a way to test a single task, live.');
      }}
   </script>)
