"use strict";

// ensure the emlc global var
window.emlc = window.emlc || {debug: {}};

(function() {

   emlc.loadJson          = loadJson;
   emlc.loadXml           = loadXml;
   emlc.profile           = profile;
   emlc.profileXml        = profileXml;
   emlc.saveJson          = saveJson;
   emlc.displayStackTrace = displayStackTrace;

   // initialize the profile table
   $(document).ready(function () {
      $('.prof-datatable').each(function() {
         var elem    = $(this);
         var order   = elem.data('order-on');
         var options = {
            info: false,
            paging: false,
            searching: false,
            order: [],
            columnDefs: [
               { targets: 'col-num',  type: 'num',    className: 'dt-body-right' },
               { targets: 'col-expr', type: 'string', className: 'cell-code' },
               { targets: '_all',     type: 'string' }
            ]
         };
         if ( order !== undefined ) {
            options.order = [
	       Math.abs(order) - 1,
	       order < 0 ? 'desc' : 'asc'
	    ];
         }
         elem.DataTable(options);
      });
   });

   function loadJson(file, jsonId)
   {
      if ( ! file ) return;
      $('#jsonFile').val('');
      var reader = new FileReader();
      reader.onload = function(e) {
         doLoadJson(e.target.result, jsonId);
      };
      reader.readAsText(file);
   }

   function doLoadJson(data, jsonId)
   {
      var reports = JSON.parse(data);
      var pretty  = JSON.stringify(reports, null, 3);
      // TODO: Display the first line...
      emlc.editorSetContent(jsonId, pretty);
      display(reports);
   }

   function loadXml(file, jsonId)
   {
      if ( ! file ) return;
      $('#xmlFile').val('');
      var reader = new FileReader();
      reader.onload = function(e) {
         var xml  = e.target.result;
         convertXmlToJson(
            xml,
            function(data) {
               doLoadJson(data, jsonId);
            });
      };
      reader.readAsText(file);
   }

   function convertXmlToJson(xml, success)
   {
      // the request content
      var fd = new FormData();
      fd.append('report', xml);
      // the request itself
      $.ajax({
         url: 'profiler/xml-to-json',
         method: 'POST',
         data: fd,
         dataType: 'text',
         processData: false,
         contentType: false,
         success: success,
         error: function(xhr, status, error) {
            alert('Error: ' + status + ' (' + error + ')\n\nSee logs for details.');
         }});
   }

   function profile(queryId, jsonId)
   {
      profileImpl(
         queryId,
         'profiler/profile-json',
         function(data) {
            doLoadJson(data, jsonId);
         });
   }

   function profileXml(queryId)
   {
      profileImpl(
         queryId,
         'profiler/profile-xml',
         function(data) {
            download(data, 'profile-report.xml', 'application/xml');
         });
   }

   function saveJson(jsonId)
   {
      download(emlc.editorContent(jsonId), 'profile-report.json', 'application/json');
   }

   function download(text, name, type)
   {
      var blob = new Blob([ text ], { type: type });
      saveAs(blob, name);
   }

   function profileImpl(queryId, endpoint, success)
   {
      // the request content
      var fd = new FormData();
      fd.append('query',  emlc.editorContent(queryId));
      fd.append('target', $('#target input:hidden').val());
      // the request itself
      $.ajax({
         url: endpoint,
         method: 'POST',
         data: fd,
         dataType: 'text',
         processData: false,
         contentType: false,
         success: success,
         error: function(xhr, status, error) {
            alert('Error: ' + status + ' (' + error + ')\n\n' + xhr.responseText + '\n\nSee logs for details.');
         }});
   }

   function display(reports)
   {
      // clear and hide all result- and stacktrace-related elements
      var table   = $('#prof-detail').DataTable();
      var stArea  = $('#stacktrace');
      table.clear();
      stArea.empty();
      $('.prof-success').hide();
      $('.prof-failure').hide();
      // if an error
      if ( reports.error ) {
         displayStackTrace(reports, stArea);
         $('.prof-failure').show();
         return;
      }
      var report  = reports.reports[0];
      var details = report.details;
      // TODO: Display the xs:duration in a human-friendly way.
      $('#total-time').text(report.summary.elapsed);
      for ( var i = 0; i < details.length; ++i ) {
         var d   = details[i];
         var loc = d.location;
         table.row.add([
            loc.uri + ':' + loc.line + ':' + loc.column,
            d.count,
            d['shallow-percent'],
            d['shallow-us'],
            d['deep-percent'],
            d['deep-us'],
            d.expression
         ]);
      }
      table.draw();
      table.columns.adjust();
      // some "width: 0" messes up the table display on Firefox
      $('#prof-detail').width('');
      $('.prof-success').show();
   }

   /*~
    * Display a stacktrace.
    *
    * @param st   The stacktrace to display, as a JSON object.
    * @param area The element where to display the stacktrace.
    */
   function displayStackTrace(st, area)
   {
      // the 'whereURI' of the frame where to stop (from the profiler itself)
      var stop  = '/profiler/profile-lib.xqy';
      var stack = st.error.stacktrace.stack;
      for ( var i = 0; i < stack.length; ++i ) {
         var frame = stack[i];
         if ( frame.whereURI == stop ) {
            break;
         }
         displayStackFrame(frame, area);
      }
   }

   function displayStackFrame(frame, area)
   {
      var div   = $('<div class="frame"></div>');
      area.append(div);
      var uri   = frame.whereURI || '';
      var line  = frame.errorline;
      var col   = frame.errorcolumn;
      div.append('<p><b>Stack frame</b>, at ' + uri + ':' + line + ':' + col + '</p>');
      div.append('<p>Context:</p>');
      div.append('<pre>' + frame.operation + '</pre>');
      div.append('<p>Code:</p>');
      var lines = '';
      for ( var i = 0; i < frame.lines.length; ++i ) {
         var l = frame.lines[i];
         if ( i == 2 ) {
            l = '<span style="color:red">' + l + '</span>';
         }
         lines = lines + l + '\n';
      }
      div.append('<pre>' + lines + '</pre>');
      if ( frame.code ) {
         var list = $('<ul></ul>');
         div.append('<p>Mappings:</p>');
         div.append(list);
         for ( i = 0; i < frame.code.length; ++i ) {
            var c = frame.code[i];
            list.append('<li><code>' + c + '</code></li>');
         }
      }
   }

})();
