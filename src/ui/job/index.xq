xquery version "3.1";

(:~
 : The job page.
 :)

import module namespace a   = "http://expath.org/ns/ml/console/admin"    at "../../lib/admin.xqy";
import module namespace v   = "http://expath.org/ns/ml/console/view"     at "../../lib/view.xqy";
import module namespace job = "http://expath.org/ns/ml/console/job/lib"  at "../../job/job-lib.xqy";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare namespace xdmp = "http://marklogic.com/xdmp";

(:~
 : The overall page function.
 :)
declare function local:page()
   as element()+
{
   <wrapper>
      <p>Everything you need to define and execute long-running jobs and tasks.</p>
      <h3>Existing</h3>
      <p>There are <b>{ job:count-jobs() }</b> jobs in the system, with the following status:</p>
      <ul>
         <li><a href="created"><code>created</code></a> - <b>{ job:count-jobs-created() }</b></li>
         <li><a href="ready"><code>ready</code></a> - <b>{ job:count-jobs-ready() }</b></li>
         <li><a href="running"><code>running</code></a> - <b>{ job:count-jobs-started() }</b></li>
         <li><a href="succeeded"><code>succeeded</code></a> - <b>{ job:count-jobs-success() }</b></li>
         <li><a href="failed"><code>failed</code></a> - <b>{ job:count-jobs-failure() }</b></li>
      </ul>
      <h3>Create</h3>
      <!-- TODO: Add here the ability to choose between a "for each" or a "while"
           job, once implemented. -->
      <p>Do what most governments fail to achieve: create a job.</p>
      {
         v:form('create', (
            v:input-text('name', 'Name', 'Short label', (), attribute required { 'required' }),
            v:input-text-area('desc', 'Description', 'Longer description (optional)'),
            v:input-exec-target('target', 'Target'),
	    v:input-radio-group('Language', (
	       v:input-radio-inline('lang', 'lang-xqy', 'xqy', 'XQuery',     'required'),
	       v:input-radio-inline('lang', 'lang-sjs', 'sjs', 'JavaScript', 'required'))),
            v:submit('Create')))
      }
   </wrapper>/*
};


v:console-page('../', 'job', 'Jobs', local:page#0,
   <lib>emlc.target</lib>)
