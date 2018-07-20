xquery version "3.1";

module namespace this = "http://expath.org/ns/ml/console/api/job/create";

import module namespace a = "http://expath.org/ns/ml/console/admin"
   at "../../lib/admin.xqy";
import module namespace t = "http://expath.org/ns/ml/console/tools"
   at "../../lib/tools.xqy";

declare namespace c    = "http://expath.org/ns/ml/console";
declare namespace json = "http://marklogic.com/xdmp/json";
declare namespace map  = "http://marklogic.com/xdmp/map";
declare namespace xdmp = "http://marklogic.com/xdmp";

(:~
 : Return the options to xdmp.eval.
 :)
declare function this:options(
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
		    map:entry('update', 'false'),
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
 : Create and save a task document.
 :)
declare function this:task(
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
 : Create and save a job document.
 :)
declare function this:job(
   $params as map:map,
   $tasks  as map:map*,
   $code   as xs:string
) as element(c:job)
{
   <job xmlns="http://expath.org/ns/ml/console">
	  <id>{       map:get($params, 'id')       }</id>
	  <uri>{      map:get($params, 'uri')      }</uri>
	  <coll>{     map:get($params, 'coll')     }</coll>
	  <created>{  map:get($params, 'created')  }</created>
	  <creation>{ $code                        }</creation>
	  <tasks> {
		 for $task in $tasks
		 return
			<task>
			   <id>{  map:get($task, 'id')  }</id>
			   <uri>{ map:get($task, 'uri') }</uri>
			</task>
	  }
	  </tasks>
   </job>
};
