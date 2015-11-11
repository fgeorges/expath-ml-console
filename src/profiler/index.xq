xquery version "3.0";

(:~
 : The profiler page.
 :)

import module namespace a = "http://expath.org/ns/ml/console/admin" at "../lib/admin.xql";
import module namespace v = "http://expath.org/ns/ml/console/view"  at "../lib/view.xql";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare variable $appservers := a:get-appservers()/a:appserver;

declare variable $script :=
   <script type="text/javascript">
      function loadJson(file, jsonId)
      {{
         if ( ! file ) return;
         $("#jsonFile").val("");
         var reader = new FileReader();
         reader.onload = function(e) {{
            doLoadJson(e.target.result, jsonId);
         }};
         reader.readAsText(file);
      }}

      function doLoadJson(data, jsonId)
      {{
         var reports = JSON.parse(data);
         var pretty  = JSON.stringify(reports, null, 3);
         // TODO: Display the first line...
         editorSetContent(jsonId, pretty);
         display(reports);
      }}

      function loadXml(file, jsonId)
      {{
         if ( ! file ) return;
         $("#xmlFile").val("");
         var reader = new FileReader();
         reader.onload = function(e) {{
            var xml  = e.target.result;
            convertXmlToJson(
               xml,
               function(data) {{
                  doLoadJson(data, jsonId);
               }});
         }};
         reader.readAsText(file);
      }}

      function convertXmlToJson(xml, success)
      {{
         // the request content
         var fd = new FormData();
         fd.append("report", xml);
         // the request itself
         $.ajax({{
            url: "profiler/xml-to-json",
            method: "POST",
            data: fd,
            dataType: "text",
            processData: false,
            contentType: false,
            success: success,
            error: function(xhr, status, error) {{
               alert("Error: " + status + " (" + error + ")\n\nSee logs for details.");
            }}}});
      }}

      function profile(queryId, jsonId)
      {{
         profileImpl(
            queryId,
            "profiler/profile-json",
            function(data) {{
               doLoadJson(data, jsonId);
            }});
      }}

      function profileXml(queryId)
      {{
         profileImpl(
            queryId,
            "profiler/profile-xml",
            function(data) {{
               download(data, "profile-report.xml", "application/xml");
            }});
      }}

      function saveJson(jsonId)
      {{
         download(editorContent(jsonId), "profile-report.json", "application/json");
      }}

      function download(text, name, type)
      {{
         var a = document.createElement("a");
         var b = new Blob([ text ], {{ type: type }});
         a.href = URL.createObjectURL(b);
         a.download = name;
         a.click();
      }}

      function profileImpl(queryId, endpoint, success)
      {{
         // the request content
         var fd = new FormData();
         fd.append("query",  editorContent(queryId));
         fd.append("target", $("#target-id").text());
         // the request itself
         $.ajax({{
            url: endpoint,
            method: "POST",
            data: fd,
            dataType: "text",
            processData: false,
            contentType: false,
            success: success,
            error: function(xhr, status, error) {{
               alert("Error: " + status + " (" + error + ")\n\nSee logs for details.");
            }}}});
      }}

      function display(reports)
      {{
         var report  = reports.reports[0];
         var details = report.details;
         // TODO: Display the xs:duration in a human-friendly way.
         $("#total-time").text(report.summary.elapsed);
         var table   = $("#prof-detail").find("tbody:last");
         table.find("tr").remove();
         for ( var i = 0; i != details.length; ++i ) {{
            var d   = details[i];
            var loc = d.location;
            var row = document.createElement("tr");
            addCell(row, loc.uri + ":" + loc.line + ":" + loc.column);
            addCell(row, d.count);
            addCell(row, d["shallow-percent"]);
            addCell(row, d["shallow-us"]);
            addCell(row, d["deep-percent"]);
            addCell(row, d["deep-us"]);
            addCell(row, d.expression, true);
            table.append(row);
         }}
      }}

      function addCell(row, text, small)
      {{
         var cell = document.createElement("td");
         var text = document.createTextNode(text);
         if ( small ) {{
            var s = document.createElement("small");
            s.appendChild(text);
            text = s;
         }}
         cell.appendChild(text);
         row.appendChild(cell);
      }}

      function selectTarget(targetId, id, targetLabel, label)
      {{
         // set the ID on the hidden element
         $("#" + targetId).text(id);
         // set the label on the display button
         var btn = $("#" + targetLabel);
         btn.text(label);
         // toggle the class of the display button if necessary
         if ( btn.hasClass("btn-danger") ) {{
            btn.removeClass("btn-danger");
            btn.addClass("btn-warning");
            // activate the "profile" and "as xml" buttons
            $("#go-profile").prop("disabled", false);
            $("#go-as-xml").prop("disabled", false);
         }}
      }}
   </script>;

declare variable $fibonacci :=
'
(: This is an example query.
 : Replace this buffer with the query you want to profile.
 :)

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
      <p>Saving as XML profile the expression but does not show it in the interface.</p>
      <p>Saving as JSON saves whatever is in the JSON editor (which is populated
         with the first profiling).</p>
      <p>The query is evaluated with the selected content database, and optionally
         using the modules database of the selected appserver.</p>

      <h3>Query</h3>
      { v:edit-text(text { $fibonacci }, 'xquery', 'prof-query', 'profile') }

      <div class="row">
         <div class="col-sm-3">
            <button id="go-profile"
                    class="btn btn-default"
                    disabled="disabled"
                    onclick='profile("prof-query", "prof-json");'>Profile</button>
            <button id="go-as-xml"
                    class="btn btn-default"
                    disabled="disabled"
                    onclick='profileXml("prof-query");'
                    style="margin-left: 10px;">As XML</button>
         </div>
         <div class="col-sm-6"/>
         <div class="col-sm-3">
            <button class="btn btn-default pull-right"
                    onclick='$("#jsonFile").click();'
                    style="margin-left: 10px;">Load JSON</button>
            <button class="btn btn-default pull-right"
                    onclick='$("#xmlFile").click();'>Load XML</button>
         </div>
      </div>

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
                  for $as in $appservers[@type eq 'http']
                  order by $as/a:name
                  return
                     local:format-as($as, 'target-id', 'target-label')
               }
               </ul>
            </div>
            <div class="btn-group" style="margin-left: 10px;">
               <button type="button" class="btn btn-default dropdown-toggle"
                       data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">
                  XDBC servers <span class="caret"/>
               </button>
               <ul class="dropdown-menu" style="min-width: 400pt"> {
                  for $as in $appservers[@type eq 'xdbc']
                  order by $as/a:name
                  return
                     local:format-as($as, 'target-id', 'target-label')
               }
               </ul>
            </div>
            <div class="btn-group" style="margin-left: 10px;">
               <button type="button" class="btn btn-default dropdown-toggle"
                       data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">
                  ODBC servers <span class="caret"/>
               </button>
               <ul class="dropdown-menu" style="min-width: 400pt"> {
                  for $as in $appservers[@type eq 'odbc']
                  order by $as/a:name
                  return
                     local:format-as($as, 'target-id', 'target-label')
               }
               </ul>
            </div>
            <div class="btn-group" style="margin-left: 10px;">
               <button type="button" class="btn btn-default dropdown-toggle"
                       data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">
                  WebDAV servers <span class="caret"/>
               </button>
               <ul class="dropdown-menu" style="min-width: 400pt"> {
                  for $as in $appservers[@type eq 'webDAV']
                  order by $as/a:name
                  return
                     local:format-as($as, 'target-id', 'target-label')
               }
               </ul>
            </div>
            <div class="btn-group pull-right active" role="group">
               <button id="target-label" type="button" class="btn btn-danger" disabled="disabled">select a source</button>
            </div>
            <div id="target-id" style="display: none"/>
         </div>
      </div>

      <h3>Profiling result</h3>
      <p>
         Total time: <span id="total-time"/>
      </p>
      <table class="table table-bordered" id="prof-detail">
         <thead>
            <th>Location</th>
            <th>Count</th>
            <th>Shallow %</th>
            <th>Shallow µs</th>
            <th>Deep %</th>
            <th>Deep µs</th>
            <th>Expression</th>
         </thead>
         <tbody/>
      </table>

      <h3>JSON report</h3>
      { v:edit-text(text { '' }, 'json', 'prof-json', 'profile') }
      <button class="btn btn-default" onclick='saveJson("prof-json");'>Save JSON</button>
      <!-- hidden fields -->
      <input type="file" id="xmlFile"  style="display: none" onchange='loadXml(this.files[0],  "prof-json")'/>
      <input type="file" id="jsonFile" style="display: none" onchange='loadJson(this.files[0], "prof-json")'/>
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

v:console-page('../', 'profiler', 'Profiler', local:page#0, $script)
