xquery version "3.1";

module namespace this = "http://expath.org/ns/ml/console/job/lib";

import module namespace a = "http://expath.org/ns/ml/console/admin" at "../lib/admin.xqy";
import module namespace t = "http://expath.org/ns/ml/console/tools" at "../lib/tools.xqy";

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
declare variable $this:stop           := 'stop';
declare variable $this:continue       := 'continue';

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
declare function this:jobs-ready() as node()*
{
   this:jobs($this:status.ready)
};

declare function this:jobs($status as xs:string?) as node()*
{
   cts:search(fn:collection(), cts:and-query((
      cts:collection-query($this:kind.job),
      $status ! cts:collection-query(.))))/*
};

declare function this:job-id($job as node()) as xs:string
{
   $job/(id|c:id)
};

declare function this:job-uri($job as node()) as xs:string
{
   $job/fn:document-uri(fn:root(.))
};

declare function this:job-name($job as node()) as xs:string? (: FIXME: Not optional, add it at creation. :)
{
   $job/(name|c:name)
};

declare function this:job-created($job as node()) as xs:dateTime
{
   $job/(created|c:created)
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
   let $modules := map:get($params, 'modules')
   return
      <job xmlns="http://expath.org/ns/ml/console">
         <id>{       map:get($params, 'id')       }</id>
         <uri>{      map:get($params, 'uri')      }</uri>
         <coll>{     map:get($params, 'coll')     }</coll>
         <name>{     map:get($params, 'name')     }</name>
         <desc>{     map:get($params, 'desc')     }</desc>
         <lang>{     map:get($params, 'lang')     }</lang>
         <target>{   map:get($params, 'target')   }</target>
         <database>{ map:get($params, 'database') }</database>
         { $modules ! <modules>{ . }</modules> }
         <created>{  map:get($params, 'created')  }</created>
      </job>
(:
TODO: Old code to be moved from old "create" to new "init".
         <creation>{ $code }</creation>
         <tasks> {
            for $task in $tasks
            return
               <task>
                  <id>{  map:get($task, 'id')  }</id>
                  <uri>{ map:get($task, 'uri') }</uri>
               </task>
         }
         </tasks>
:)
};
