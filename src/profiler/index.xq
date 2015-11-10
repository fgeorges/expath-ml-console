xquery version "3.0";

(:~
 : The profiler page.
 :)

import module namespace a = "http://expath.org/ns/ml/console/admin" at "../lib/admin.xql";
import module namespace v = "http://expath.org/ns/ml/console/view"  at "../lib/view.xql";

declare default element namespace "http://www.w3.org/1999/xhtml";

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
         fd.append("query", editorContent(queryId));
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
            addCell(row, d.expression);
            table.append(row);
         }}
      }}

      function addCell(row, text)
      {{
         var cell = document.createElement("td");
         var text = document.createTextNode(text);
         cell.appendChild(text);
         row.appendChild(cell);
      }}
   </script>;

declare variable $fibonacci :=
'
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

local:fib-recur(10),
local:fib-iter(10)
';

(:~
 : The overall page function.
 :)
declare function local:page()
   as element()+
{
   <wrapper>
      <p>The expression to profile:</p>
      { v:edit-text(text { $fibonacci }, 'xquery', 'prof-query', 'profile') }
      <button class="btn btn-default"
              onclick='profile("prof-query", "prof-json");'>Profile</button>
      <button class="btn btn-default"
              onclick='profileXml("prof-query");'
              style="margin-left: 10px;">As XML</button>
      <button class="btn btn-default pull-right"
              onclick='$("#jsonFile").click();'
              style="margin-left: 10px;">Load JSON</button>
      <button class="btn btn-default pull-right"
              onclick='$("#xmlFile").click();'>Load XML</button>
      <p/>
      <p>The profiler output:</p>
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
      <p/>
      <p>The JSON report:</p>
      { v:edit-text(text { '' }, 'json', 'prof-json', 'profile') }
      <button class="btn btn-default" onclick='saveJson("prof-json");'>Save JSON</button>
      <!-- hidden fields -->
      <input type="file" id="xmlFile"  style="display: none" onchange='loadXml(this.files[0],  "prof-json")'/>
      <input type="file" id="jsonFile" style="display: none" onchange='loadJson(this.files[0], "prof-json")'/>
   </wrapper>/*
};

v:console-page('../', 'profiler', 'Profiler', local:page#0, $script)
