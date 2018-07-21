xquery version "3.1";

module namespace this = "http://expath.org/ns/ml/console/api/job/start";

import module namespace a = "http://expath.org/ns/ml/console/admin"
   at "../../lib/admin.xqy";
import module namespace b = "http://expath.org/ns/ml/console/binary"
   at "../../lib/binary.xqy";
import module namespace t = "http://expath.org/ns/ml/console/tools"
   at "../../lib/tools.xqy";

declare namespace err  = "http://www.w3.org/2005/xqt-errors";
declare namespace c    = "http://expath.org/ns/ml/console";
declare namespace cts  = "http://marklogic.com/cts";
declare namespace json = "http://marklogic.com/xdmp/json";
declare namespace map  = "http://marklogic.com/xdmp/map";
declare namespace xdmp = "http://marklogic.com/xdmp";

declare variable $kind.task      := '/kind/task';
declare variable $status.inited  := '/status/initialised';
declare variable $status.started := '/status/started';
declare variable $status.success := '/status/success';
declare variable $status.failure := '/status/failure';
declare variable $stop           := 'stop';
declare variable $continue       := 'continue';

(:~
 : Start a job, given its ID and the code to execute its tasks.
 :)
declare function this:start(
   $id   as xs:string,
   $uri  as xs:string,
   $coll as xs:string,
   $code as xs:string
) as empty-sequence()
{
   if ( fn:not($status.inited = xdmp:document-get-collections($uri)) ) then
      fn:error((), 'Job not in initialised state: ' || $uri)
   else (
      (: spawn so log msg appears in task server logs :)
      xdmp:spawn-function(
         function() {
            this:log('============================================================'),
            this:log('Start job: ' || $uri),
            xdmp:document-remove-collections($uri, $status.inited),
            xdmp:document-add-collections($uri, $status.started)
         },
         <options xmlns="xdmp:eval">
            <update>true</update>
         </options>),
      let $job      as node()     := fn:doc($uri)/(job, c:job)
      let $lang     as xs:string  := $job/(lang, c:lang)
      let $database as xs:string  := $job/(database, c:database)
      let $modules  as xs:string? := $job/(modules,  c:modules)
      let $options :=
             <options xmlns="xdmp:eval">
                <database>{ $database }</database>
                { $modules ! <modules>{ . }</modules> }
             </options>
      return
         (: TODO: To start N "threads" in parallel, start N tasks here instead of
            one, each one, when it has finished, will start the next one. :)
         this:enqueue($uri, $coll, function($task) {
            if ( $lang eq 'xqy' ) then
               xdmp:eval($code,(xs:QName('task'), $task), $options)
            else
               xdmp:javascript-eval($code,('task', $task), $options)
         })
   )
};

declare function this:enqueue(
   $uri  as xs:string,
   $coll as xs:string,
   $impl as function(node()) as item()*
)
{
   xdmp:spawn-function(
      function() {
         try {
            let $res := xdmp:invoke-function(function() { this:exec-next-task($uri, $coll, $impl) })
            return
               if ( $res eq $continue ) then (
                  this:enqueue($uri, $coll, $impl)
               )
               else (
                  this:log('Stop job: ' || $uri),
                  this:log('------------------------------------------------------------')
               )
         }
         catch * {
            (: TODO: Flip the job tasks still "to-run" to "ignored", or "not-run"?
               (in addition to "failure"? :)
            let $doc as node() := fn:doc($uri)/(job, c:job)
            return (
               this:log('Job failed: ' || $uri),
               this:log('    ' || $err:description),
               this:push-error($doc, $err:description),
               xdmp:document-remove-collections($uri, $status.started),
               xdmp:document-add-collections($uri, $status.failure)
            )
         }
      },
      <options xmlns="xdmp:eval">
        <update>true</update>
      </options>)
};

declare function this:next-task($coll as xs:string) as xs:string?
{
   cts:uris((), (),
      cts:and-query(
         ($coll, $kind.task, $status.inited) ! cts:collection-query(.)
      ))[1]
};

declare function this:exec-next-task(
   $uri  as xs:string,
   $coll as xs:string,
   $impl as function(node()) as item()*
) as xs:string
{
   let $task := this:next-task($coll)
   return
      if ( fn:exists($task) ) then (
         this:log('Execute task: ' || $task),
         this:exec-task($uri, $coll, $impl, $task)
      )
      else (
         xdmp:document-remove-collections($uri, $status.started),
         xdmp:document-add-collections($uri, $status.success),
         $stop
      )
};

declare function this:exec-task(
   $job  as xs:string,
   $coll as xs:string,
   $impl as function(node()) as item()*,
   $uri  as xs:string
)
{
   let $task as node() := fn:doc($uri)/(task, c:task)
   return
      try {
         (: TODO: The result of the task should be saved in the task doc. :)
         let $noout := $impl($task)
         return (
            xdmp:document-remove-collections($uri, $status.inited),
            xdmp:document-add-collections($uri, $status.success),
            $continue
         )
      }
      catch * {
         (: TODO: Flip the job tasks still "to-run" to "ignored", or "not-run"? :)
         this:log('Task failed: ' || $uri),
         this:log('    ' || $err:description),
         this:push-error($task, $err:description),
         xdmp:document-remove-collections($uri, $status.inited),
         xdmp:document-add-collections($uri, $status.failure),
         xdmp:document-remove-collections($job, $status.started),
         xdmp:document-add-collections($job, $status.failure),
         $stop
      }
};


(:
*********************************
            HERE...
*********************************
:)


declare function this:push-error(
   $doc as node((: job or task, JSON or XML (root property object or element) :)),
   $msg as xs:string
)
{
   (: XML :)
   if ( $doc instance of element() ) then
      xdmp:node-insert-child($doc, <error xmlns="http://expath.org/ns/ml/console">{ $msg }</error>)
   (: JSON :)
   else if ( b:is-object($doc) ) then
      let $array as item()? := b:get-arrays($doc)[fn:node-name(.) eq 'error']
      return
         if ( fn:exists($array) ) then
            xdmp:node-insert-child($array, text { $msg })
         else
            xdmp:node-insert-child($doc, b:get-arrays(b:object('error', b:array($msg))))
   (: unexpected :)
   else
      let $desc := xdmp:describe($doc)
      return (
         this:log('Fatal error when pushing error, node is neither element or object: ' || $desc),
         this:log('    Original error: ' || $msg)
      )
};

declare function this:log($msg as xs:string) as empty-sequence()
{
   xdmp:log('emlc:job: ' || $msg)
};


(:
*********************************
An example  task impl, to test...
*********************************

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
:)
