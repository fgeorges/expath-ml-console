xquery version "3.0";

(:~
 : The profiler page.
 :)

import module namespace a = "http://expath.org/ns/ml/console/admin" at "../lib/admin.xqy";
import module namespace v = "http://expath.org/ns/ml/console/view"  at "../lib/view.xqy";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare variable $appservers := a:get-appservers()/a:appserver;

declare variable $fibonacci :=
'
(: This is an example query.
 : Replace this buffer with the query you want to profile.
 :)

xquery version "3.0";

(:~
 : Fibonacci, recursive version.
 :)
declare function local:fib-recur($n as xs:integer) as xs:integer?
{
   if ( $n lt 0 ) then
      ()
   else if ( $n eq 0 ) then
      0
   else if ( $n eq 1 ) then
      1
   else
      local:fib-recur($n - 2) + local:fib-recur($n - 1)
};

(:~
 : Fibonacci, iterative version.
 :)
declare function local:fib-iter($n as xs:integer) as xs:integer?
{
   if ( $n lt 0 ) then
      ()
   else if ( $n eq 0 ) then
      0
   else
      local:fib-iter-1($n, 0, 1)
};

declare function local:fib-iter-1($n as xs:integer, $m1 as xs:integer, $m2 as xs:integer) as xs:integer
{
   if ( $n eq 1 ) then
      $m2
   else
      local:fib-iter-1($n - 1, $m2, $m1 + $m2)
};

(: Call them. :)

local:fib-recur(20),
local:fib-iter(20)
';

(:~
 : The overall page function.
 :)
declare function local:page()
   as element()+
{
   <wrapper>
      <p>The profiler helps you profile an XQuery expression, save the profiling
         report (both XML and JSON) and load existing reports (both XML and JSON).</p>
      <p>The button <b>Profile</b> profiles the expression, displays the profile
         report in the table, and display it as JSON below the table.</p>
      <p>The button <b>As XML</b> profiles the expression and returns the XML report,
         but does not show it in the interface.</p>
      <p>The button <b>Save JSON</b> saves whatever is in the JSON editor (which is
         populated with each <b>Profile</b> pass).</p>
      <p>The query is evaluated with the selected content database, and optionally
         using the modules database of the selected appserver (when you select an
         appserver instead of a database).  Before evaluating an expression, you
         need to <b>select a source</b> first.</p>

      <h3>Source</h3>
      { v:input-db-widget('target') }

      <h3>Query</h3>
      { v:edit-text(text { $fibonacci }, 'xquery', 'prof-query', 'profile') }

      <div class="row">
         <div class="col">
            <div class="float-right">
               <button id="go-profile"
                       class="btn btn-outline-secondary need-target"
                       disabled="disabled"
                       onclick='emlc.profile("prof-query", "prof-json");'>Profile</button>
               <button id="go-as-xml"
                       class="btn btn-outline-secondary need-target"
                       disabled="disabled"
                       onclick='emlc.profileXml("prof-query");'
                       style="margin-left: 10px;">As XML</button>
            </div>
         </div>
      </div>
      <p/>

      <h3 class="prof-success">Profiling result</h3>
      <p class="prof-success">
         Total time: <span id="total-time"/>
      </p>
      <table class="table table-bordered prof-datatable prof-success" id="prof-detail" data-order-on="-3">
         <thead>
            <th>Location</th>
            <th class="col-num">Count</th>
            <th class="col-num">Shallow %</th>
            <th class="col-num">Shallow µs</th>
            <th class="col-num">Deep %</th>
            <th class="col-num">Deep µs</th>
            <th class="col-expr">Expression</th>
         </thead>
         <tbody/>
      </table>
      <div class="row">
         <div class="col">
            <div class="float-right">
               <button class="btn btn-outline-secondary"
                       onclick='$("#jsonFile").click();'>Load JSON</button>
               <button class="btn btn-outline-secondary"
                       onclick='$("#xmlFile").click();'
                       style="margin-left: 10px;">Load XML</button>
            </div>
         </div>
      </div>
      <p/>

      <h3 class="prof-failure" style="display: none">Stacktrace</h3>
      <div id="stacktrace" class="prof-failure" style="display: none"/>

      <h3>JSON report</h3>
      { v:edit-text(text { '' }, 'json', 'prof-json', 'profile') }
      <button class="btn btn-outline-secondary float-right" style="margin-bottom: 20pt"
              onclick='emlc.saveJson("prof-json");'>Save JSON</button>
      <!-- hidden fields -->
      <input type="file" id="xmlFile"  style="display: none" onchange='emlc.loadXml(this.files[0],  "prof-json")'/>
      <input type="file" id="jsonFile" style="display: none" onchange='emlc.loadJson(this.files[0], "prof-json")'/>
   </wrapper>/*
};

v:console-page('../', 'profiler', 'Profiler', local:page#0, (
   <lib>filesaver</lib>,
   <lib>emlc.ace</lib>,
   <lib>emlc.profiler</lib>,
   <lib>emlc.target</lib>))
