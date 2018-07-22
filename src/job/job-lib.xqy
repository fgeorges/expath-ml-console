xquery version "3.1";

module namespace this = "http://expath.org/ns/ml/console/job/lib";

declare namespace c    = "http://expath.org/ns/ml/console";
declare namespace cts  = "http://marklogic.com/cts";
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
