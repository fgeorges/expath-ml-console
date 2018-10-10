# Notes on jobs

## Init job

'use strict';

declareUpdate();

const jobid = 'abc-123';
const coll  = '/jobs/' + jobid;
const uri   = coll + '/job.json';

const job = { job: {
  id:   jobid,
  coll: coll,
  tasks: [
    {id: jobid + '/001', uri: coll + '/task-001.json'},
    {id: jobid + '/002', uri: coll + '/task-002.json'},
    {id: jobid + '/003', uri: coll + '/task-003.json'}
  ]
}};

const task1 = { task: {
  id:    jobid + '/001',
  chunk: '001'
}};

const task2 = { task: {
  id:    jobid + '/002',
  chunk: '002'
}};

const task3 = { task: {
  id:    jobid + '/003',
  chunk: '003'
}};

xdmp.documentInsert(uri, job, {collections: ['/kind/job', '/status/to-run', coll]});
xdmp.documentInsert(job.job.tasks[0].uri, task1, {collections: ['/kind/task', '/status/to-run', coll]});
xdmp.documentInsert(job.job.tasks[1].uri, task2, {collections: ['/kind/task', '/status/to-run', coll]});
xdmp.documentInsert(job.job.tasks[2].uri, task3, {collections: ['/kind/task', '/status/to-run', coll]});

## Reset job

xquery version "3.1";

declare namespace xdmp = "http://marklogic.com/xdmp";

declare variable $job     := '/jobs/abc-123';
declare variable $to-run  := '/status/to-run';
declare variable $started := '/status/started';
declare variable $success := '/status/success';
declare variable $failure := '/status/failure';

declare function local:reset($uri as xs:string) {
  xdmp:document-remove-collections($uri, $started),
  xdmp:document-remove-collections($uri, $success),
  xdmp:document-remove-collections($uri, $failure),
  xdmp:document-add-collections($uri, $to-run)
};

(: reset job and its tasks to to-run :)
fn:collection($job)[/job]  ! fn:document-uri(.) ! local:reset(.),
fn:collection($job)[/task] ! fn:document-uri(.) ! local:reset(.),
xdmp:spawn-function(function() {
  xdmp:log('*** Reset job: ' || $job)
})

## Run job

xquery version "1.0-ml";
(: 1.0-ml instead of 3.1, to push error to either XML or JSON :)

declare namespace err  = "http://www.w3.org/2005/xqt-errors";
declare namespace cts  = "http://marklogic.com/cts";
declare namespace xdmp = "http://marklogic.com/xdmp";

declare variable $job      := '/jobs/abc-123';
declare variable $kind     := '/kind/task';
declare variable $to-run   := '/status/to-run';
declare variable $started  := '/status/started';
declare variable $success  := '/status/success';
declare variable $failure  := '/status/failure';
declare variable $stop     := 'stop';
declare variable $continue := 'continue';

declare function local:start($job, $impl) {
  xdmp:spawn-function(
    function() {
      let $uri := fn:collection($job)[/job] ! fn:document-uri(.)
      return (
        xdmp:log('===================='),
        xdmp:log('Start job: ' || $job),
        xdmp:document-remove-collections($uri, $to-run),
        xdmp:document-add-collections($uri, $started)
      )
    },
    <options xmlns="xdmp:eval">
      <update>true</update>
    </options>),
  local:enqueue($job, $impl)
};

declare function local:enqueue($job, $impl) {
  xdmp:spawn-function(
    function() {
      try {
        local:recursive-task($job, $impl)
      }
      catch * {
        (: TODO: Add the error message to the job document. :)
        (: TODO: Flip the job tasks still "to-run" to "ignored", or "not-run"? :)
        (: TODO: Pass directly the job URI in addition to its collection? :)
        let $doc := fn:collection($job)[/job]
        let $uri := fn:document-uri($doc)
        return (
          xdmp:log('Job failed: ' || $job),
          xdmp:log('    ' || $err:description),
          local:push-error($doc/job, $err:description),
          xdmp:document-remove-collections($uri, $started),
          xdmp:document-add-collections($uri, $failure)
        )
      }
    },
    <options xmlns="xdmp:eval">
      <update>true</update>
    </options>)
};

declare function local:next-task() as xs:string? {
  cts:uris((), (),
    cts:and-query(
      ($job, $kind, $to-run) ! cts:collection-query(.)
    ))[1]
};

declare function local:recursive-task($job as xs:string, $impl as function(node()) as item()*) {
  let $res := xdmp:invoke-function(function() { local:exec-next-task($job, $impl) })
  return
    if ( $res eq $continue ) then (
      local:enqueue($job, $impl)
    )
    else (
      xdmp:log('Stop job: ' || $job),
      xdmp:log('--------------------')
    )
};

declare function local:exec-next-task($job, $impl) as xs:string {
  let $uri := local:next-task()
  return
    if ( fn:exists($uri) ) then (
      xdmp:log('Execute task: ' || $job),
      local:exec-task($job, $impl, $uri)
    )
    else (
      let $job-uri := fn:collection($job)[/job]  ! fn:document-uri(.)
      return (
        xdmp:document-remove-collections($job-uri, $started),
        xdmp:document-add-collections($job-uri, $success),
        $stop
      )
    )
};

declare function local:exec-task($job, $impl, $uri) {
  try {
    let $task  := fn:doc($uri)/task
    let $noout := $impl($task)
    return (
      xdmp:document-remove-collections($uri, $to-run),
      xdmp:document-add-collections($uri, $success),
      $continue
    )
  }
  catch * {
    (: TODO: Add the error message to the task document. :)
    (: TODO: Flip the job tasks still "to-run" to "ignored", or "not-run"? :)
    let $job-uri := fn:collection($job)[/job]  ! fn:document-uri(.)
    return (
      xdmp:log('Task failed: ' || $uri),
      xdmp:log('    ' || $err:description),
      local:push-error(fn:doc($uri)/task, $err:description),
      xdmp:document-remove-collections($uri, $to-run),
      xdmp:document-add-collections($uri, $failure),
      xdmp:document-remove-collections($job-uri, $started),
      xdmp:document-add-collections($job-uri, $failure),
      $stop
    )
  }
};

declare function local:push-error($doc as node(), $msg as xs:string) {
  (: XML :)
  if ( $doc instance of element() ) then (
    (: TODO: Adapt to the final namespace for job/task documents :)
    xdmp:node-insert-child($doc, <error>{ $msg }</error>)
  )
  (: JSON :)
  else if ( $doc instance of object-node() ) then (
    if ( fn:exists($doc/array-node('error')) ) then
      xdmp:node-insert-child($doc/array-node('error'), text { $msg })
    else
      xdmp:node-insert-child($doc, object-node { 'error': array-node { $msg } }/array-node())
  )
  (: unexpected :)
  else (
    xdmp:log('Fatal error when pushing error, node is neither element or object: ' || xdmp:describe($doc)),
    xdmp:log('    Original error: ' || $msg)
  )
};

declare function local:task-impl($task as node()) {
  let $i := xs:integer($task/chunk)
  let $u := (for $u in fn:collection() ! fn:document-uri(.) order by $u return $u)[$i]
  let $d := fn:doc($u)/sample
  return (
    fn:error((), 'BOOM!'),
    xdmp:log('Executing task implem: ' || $d/hello),
    xdmp:node-insert-child(
      $d/array-node('tasks'),
      text { $task/id })
  )
};

local:start(
  $job,
  function($task) {
    (: use invoke-function only when needed to set content and/or modules databases :)
    xdmp:invoke-function(
      function() {
        local:task-impl($task)
      },
      <options xmlns="xdmp:eval">
        <database>{ xdmp:database('xxx-foobar-content') }</database>
      </options>)
  })

