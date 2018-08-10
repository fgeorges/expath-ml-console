xquery version "3.1";

module namespace this = "http://expath.org/ns/ml/console/job/lib";

import module namespace a = "http://expath.org/ns/ml/console/admin"  at "../lib/admin.xqy";
import module namespace b = "http://expath.org/ns/ml/console/binary" at "../lib/binary.xqy";
import module namespace t = "http://expath.org/ns/ml/console/tools"  at "../lib/tools.xqy";

declare namespace err  = "http://www.w3.org/2005/xqt-errors";
declare namespace c    = "http://expath.org/ns/ml/console";
declare namespace cts  = "http://marklogic.com/cts";
declare namespace json = "http://marklogic.com/xdmp/json";
declare namespace map  = "http://marklogic.com/xdmp/map";
declare namespace xdmp = "http://marklogic.com/xdmp";

declare variable $this:kind.job       := '/kind/job';
declare variable $this:kind.task      := '/kind/task';
declare variable $this:status.created := '/status/created';
declare variable $this:status.ready   := '/status/ready';
declare variable $this:status.started := '/status/started';
declare variable $this:status.success := '/status/success';
declare variable $this:status.failure := '/status/failure';
declare variable $this:resp.stop      := 'stop';
declare variable $this:resp.continue  := 'continue';

declare function this:count-jobs() as xs:integer
{
   this:count-jobs-status(())
};

declare function this:count-jobs-created() as xs:integer
{
   this:count-jobs-status($this:status.created)
};

declare function this:count-jobs-ready() as xs:integer
{
   this:count-jobs-status($this:status.ready)
};

declare function this:count-jobs-started() as xs:integer
{
   this:count-jobs-status($this:status.started)
};

declare function this:count-jobs-success() as xs:integer
{
   this:count-jobs-status($this:status.success)
};

declare function this:count-jobs-failure() as xs:integer
{
   this:count-jobs-status($this:status.failure)
};

declare function this:count-jobs-status($status as xs:string?) as xs:integer
{
   fn:count(
      cts:uris('', (), cts:and-query((
	 cts:collection-query($this:kind.job),
         $status ! cts:collection-query(.)))))
};

(: TODO: Paginate. :)
declare function this:jobs-created() as node()*
{
   this:jobs($this:status.created)
};

(: TODO: Paginate. :)
declare function this:jobs-ready() as node()*
{
   this:jobs($this:status.ready)
};

(: TODO: Paginate. :)
declare function this:jobs-started() as node()*
{
   this:jobs($this:status.started)
};

(: TODO: Paginate. :)
declare function this:jobs-success() as node()*
{
   this:jobs($this:status.success)
};

(: TODO: Paginate. :)
declare function this:jobs-failure() as node()*
{
   this:jobs($this:status.failure)
};

declare function this:jobs($status as xs:string?) as node()*
{
   cts:search(fn:collection($this:kind.job)/*, cts:and-query((
      $status ! cts:collection-query(.))))
};

declare function this:job($id as xs:string) as node()?
{
   cts:search(fn:collection($this:kind.job)/*, cts:or-query((
      cts:json-property-value-query('id', $id),
      cts:element-value-query(xs:QName('c:id'), $id))))
};

declare function this:status($job as node()) as xs:string
{
   this:uri($job)
   ! xdmp:document-get-collections(.)[. = (
         $this:status.created,
         $this:status.ready,
         $this:status.started,
         $this:status.success,
         $this:status.failure
      )]
};

declare function this:id($doc as node()) as xs:string
{
   $doc/(id|c:id)
};

declare function this:uri($doc as node()) as xs:string
{
   $doc/(uri|c:uri)
};

declare function this:collection($job as node()) as xs:string
{
   $job/(coll|c:coll)
};

declare function this:name($job as node()) as xs:string? (: FIXME: Not optional, add it at creation. :)
{
   $job/(name|c:name)
};

declare function this:desc($job as node()) as xs:string
{
   $job/(desc|c:desc)
};

declare function this:lang($job as node()) as xs:string
{
   $job/(lang|c:lang)
};

declare function this:database($job as node()) as xs:string
{
   $job/(database|c:database)
};

declare function this:modules($job as node()) as xs:string?
{
   $job/(modules|c:modules)
};

declare function this:created($doc as node()) as xs:dateTime
{
   $doc/(created|c:created) ! xs:dateTime(.)
};

declare function this:init-module($job as node()) as xs:string
{
   $job/(init|c:init)
};

declare function this:exec-module($job as node()) as xs:string
{
   $job/(exec|c:exec)
};

declare function this:tasks($job as node()) as node()*
{
   cts:search(fn:collection($this:kind.task)/*,
      cts:collection-query(this:collection($job)))
};

declare function this:task($id as xs:string) as node()?
{
   cts:search(fn:collection($this:kind.task)/*, cts:or-query((
      cts:json-property-value-query('id', $id),
      cts:element-value-query(xs:QName('c:id'), $id))))
};

declare function this:order($task as node()) as xs:string
{
   $task/(order|c:order)
};

declare function this:num($task as node()) as xs:string
{
   $task/(num|c:num)
};

declare function this:label($task as node()) as xs:string
{
   $task/(label|c:label)
};

declare function this:set-status($job as node(), $coll as xs:string) as empty-sequence()
{
   xdmp:document-remove-collections(this:uri($job), (
      $this:status.created,
      $this:status.ready,
      $this:status.started,
      $this:status.success,
      $this:status.failure
   )),
   xdmp:document-add-collections(this:uri($job), $coll)
};

(:~
 : Return the resolved targets (content db, and maybe modules db.)
 :)
declare function this:resolve-target(
   $target as xs:string
) as map:map
{
   if ( $target castable as xs:unsignedLong ) then
      let $id    := xs:unsignedLong($target)
      let $thing := a:get-appserver-or-database($id)
      let $db    := $id[$thing[self::a:database]]
      let $mod   := $thing[self::a:appserver]/( a:modules-db/@id, 0[$thing/a:modules-path] )
      return
         map:new((
            if ( $thing[self::a:database] ) then (
               map:entry('database', $id)
            )
            else (
               map:entry('database', $thing/a:db/xs:unsignedLong(@id)),
               map:entry('modules',  ( $thing/a:modules-db/xs:unsignedLong(@id), 0 )[1])
            )))
   else
      t:error('invalid-id', 'Invalid DB or AS ID: ' || $target)
};

(:~
 : Create a task document.
 :)
declare function this:make-task(
   $params as map:map,
   $chunk  as item()+
) as element(c:task)
{
   <task xmlns="http://expath.org/ns/ml/console">
      <id>{       map:get($params, 'id')       }</id>
      <uri>{      map:get($params, 'uri')      }</uri>
      <order>{    map:get($params, 'order')    }</order>
      <num>{      map:get($params, 'num')      }</num>
      <label>{    map:get($params, 'label')    }</label>
      <created>{  map:get($params, 'created')  }</created>
      <chunk>{    $chunk                       }</chunk>
   </task>
};

(:~
 : Create a job document.
 :)
declare function this:make-job(
   $params as map:map
) as element(c:job)
{
   <job xmlns="http://expath.org/ns/ml/console">
      <id>{       map:get($params, 'id')       }</id>
      <uri>{      map:get($params, 'uri')      }</uri>
      <coll>{     map:get($params, 'coll')     }</coll>
      <name>{     map:get($params, 'name')     }</name>
      <desc>{     map:get($params, 'desc')     }</desc>
      <lang>{     map:get($params, 'lang')     }</lang>
      <target>{   map:get($params, 'target')   }</target>
      <database>{ map:get($params, 'database') }</database>
      { map:get($params, 'modules') ! <modules>{ . }</modules> }
      <created>{  map:get($params, 'created')  }</created>
      <init>{     map:get($params, 'init')     }</init>
      <exec>{     map:get($params, 'exec')     }</exec>
   </job>
};

(:~
 : Start a job, given its ID and the code to execute its tasks.
 :)
declare function this:start($id as xs:string) as empty-sequence()
{
   let $job    := this:job($id)
   let $status := this:status($job)
   let $uri    := this:uri($job)
   let $name   := this:name($job)
   return
      if ( fn:not($status eq $this:status.ready) ) then
	 fn:error((), 'Job ' || $id || ' not in state ready: ' || $status)
      else (
	 (: spawn so log msg appears in task server logs :)
	 xdmp:spawn-function(
	    function() {
	       xdmp:log('============================================================'),
	       xdmp:log('Start job ' || $id || ': ' || $name),
	       xdmp:document-remove-collections($uri, $this:status.ready),
	       xdmp:document-add-collections($uri, $this:status.started)
	    },
	    <options xmlns="xdmp:eval">
	       <update>true</update>
	    </options>),
         let $coll    := this:collection($job)
         let $lang    := this:lang($job)
         let $code    := fn:doc(this:exec-module($job))
         let $content := this:database($job)
         let $modules := this:modules($job)
	 let $options :=
		<options xmlns="xdmp:eval">
		   <database>{ $content }</database>
		   { $modules ! <modules>{ . }</modules> }
		</options>
	 return
	    (: TODO: To start N "threads" in parallel, start N tasks here instead of
	       one.  Each task, once it has finished, will start the next one. :)
	    this:enqueue($id, $uri, $coll, function($task) {
	       if ( $lang eq 'xqy' ) then
		  xdmp:eval($code, (xs:QName('task'), $task), $options)
	       else
		  xdmp:javascript-eval($code, ('task', $task), $options)
	    })
      )
};

declare function this:enqueue(
   $id   as xs:string,
   $uri  as xs:string,
   $coll as xs:string,
   $impl as function(node()) as item()*
)
{
   xdmp:spawn-function(
      function() {
         try {
            let $res := xdmp:invoke-function(function() { this:exec-next-task($id, $uri, $coll, $impl) })
            return
               if ( $res eq $resp.continue ) then (
                  this:enqueue($id, $uri, $coll, $impl)
               )
               else (
                  xdmp:log('Stop job: ' || $id),
                  xdmp:log('------------------------------------------------------------')
               )
         }
         catch * {
            (: TODO: Flip the job tasks still "to-run" to "ignored", or "not-run"?
               (in addition to "failure"? :)
            let $job := this:job($id)
            let $uri := this:uri($job)
            return (
               xdmp:log('Job failed: ' || $id),
               xdmp:log('    ' || $err:description),
               this:push-error($job, $err:description),
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
         ($coll, $kind.task, $status.created) ! cts:collection-query(.)
      ))[1]
};

declare function this:exec-next-task(
   $id   as xs:string,
   $uri  as xs:string,
   $coll as xs:string,
   $impl as function(node()) as item()*
) as xs:string
{
   let $task := this:next-task($coll)
   return
      if ( fn:exists($task) ) then (
         xdmp:log('Execute task: ' || $task),
         this:exec-task($id, $uri, $coll, $impl, $task)
      )
      else (
         xdmp:document-remove-collections($uri, $status.started),
         xdmp:document-add-collections($uri, $status.success),
         $resp.stop
      )
};

declare function this:exec-task(
   $id   as xs:string,
   $juri as xs:string,
   $coll as xs:string,
   $impl as function(node()) as item()*,
   $turi as xs:string
)
{
   let $task as node() := fn:doc($turi)/*
   return
      try {
         (: TODO: The result of the task should be saved in the task doc. :)
         let $noout := $impl($task)
         return (
            xdmp:document-remove-collections($turi, $status.created),
            xdmp:document-add-collections($turi, $status.success),
            $resp.continue
         )
      }
      catch * {
         (: TODO: Flip the job tasks still "to-run" to "ignored", or "not-run"? :)
         xdmp:log('Task failed: ' || $turi),
         xdmp:log('    ' || $err:description),
         this:push-error($task, $err:description),
         xdmp:document-remove-collections($turi, $status.created),
         xdmp:document-add-collections($turi, $status.failure),
         xdmp:document-remove-collections($juri, $status.started),
         xdmp:document-add-collections($juri, $status.failure),
         $resp.stop
      }
};

declare function this:push-error(
   $doc as node((: job or task, JSON or XML (root property object or element) :)),
   $msg as xs:string
)
{
   (: XML :)
   if ( $doc instance of element() ) then
      xdmp:node-insert-child($doc,
         <error xmlns="http://expath.org/ns/ml/console">{ $msg }</error>)
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
         xdmp:log('Fatal error when pushing error, node is neither element or object: ' || $desc),
         xdmp:log('    Original error: ' || $msg)
      )
};
