var highlight = ace.require('ace/ext/static_highlight');

function initCodeSnippet()
{
   var elem = $(this);
   highlight(
      this,
      {
         mode:       elem.attr('ace-mode'),
         theme:      elem.attr('ace-theme'),
         showGutter: elem.attr('ace-gutter'),
         trim:       false,
         startLineNumber: 1
      },
      function (highlighted) {
         // nothing
      });
}

// contains all editors on the page, by ID
var editors = { };

function initCodeEditor()
{
   var elem = $(this);
   var e    = { };
   e.id     = elem.attr('id');
   e.uri    = elem.attr('ace-uri');
   e.top    = elem.attr('ace-top');
   e.theme  = elem.attr('ace-theme');
   e.mode   = elem.attr('ace-mode');
   e.editor = ace.edit(elem.get(0));
   e.editor.setTheme(e.theme);
   e.editor.getSession().setMode(e.mode);
   editors[e.id] = e;
}

// initialise page components
$(document).ready(function () {
   // actually initialise code snippets and editors
   $('.code').each(initCodeSnippet);
   $('.editor').each(initCodeEditor);
   // initialise the data tables
   // TODO: This is specific to the profiler table, this class should not have
   // as a generic name as 'datatables'
   $('.datatable').DataTable({
      info: false,
      paging: false,
      searching: false,
      order: [2, 'desc'],
      columnDefs: [
         { targets: 'col-num',  type: 'num',    className: 'dt-body-right' },
         { targets: 'col-expr', type: 'string', className: 'cell-small' },
         { targets: '_all',     type: 'string' }
      ]
   });
});

// id is the id of the ACE editor element
// type is either 'xml' or 'text'
function saveDoc(id, type)
{
   // get the ACE doc
   var info     = editors[id];
   var endpoint = info.top + 'save-' + type;
   // the request content
   var fd = new FormData();
   fd.append('doc', editorContent(id));
   fd.append('uri', info.uri);
   // the request itself
   $.ajax({
      url: endpoint,
      method: 'POST',
      data: fd,
      dataType: 'text',
      processData: false,
      contentType: false,
      success: function(data) {
         alert('Success: ' + data);
      },
      error: function(xhr, status, error) {
         alert('Error: ' + status + ' (' + error + ')\n\nSee logs for details.');
      }});
};

// id is the id of the ACE editor element
function deleteDoc(id)
{
   $('#' + id + '-delete').submit();
};

function editorDocument(id)
{
   var info = editors[id];
   if ( info ) {
      var editor = info.editor;
      if ( editor ) {
         var session = editor.getSession();
         if ( session ) {
            return session.getDocument();
         }
      }
   }
};

function editorContent(id)
{
   var doc = editorDocument(id);
   if ( doc ) {
      return doc.getValue();
   }
};

function editorSetContent(id, value)
{
   var doc = editorDocument(id);
   if ( doc ) {
      doc.setValue(value);
   }
};

/* ==== Browser support ======================================================== */

/**
 * Delete all selected URIs.
 *
 * There are 2 forms (with the ID origId and hiddenId resp.)  The original form
 * is the list of URIs displayed to the user.  The hidden form is a form used to
 * implement the solution.
 *
 * This code goes through all checked checkboxes in the first form (the URIs are
 * displayed each with a checkbox).  They all have a name of the form 'delete-1',
 * 'delete-2', etc., and must each have a corresponding form text field with
 * name 'name-1', 'name-2', etc., with the corresponding URI.
 *
 * For each of the checked checkbox, a text field is created in the hidden form,
 * with the name 'uri-to-delete-1', 'uri-to-delete-2', etc.  The hidden form is
 * then submitted.
 *
 * @param origId    The id of the original form element.
 * @param hiddenId  The id of the hidden form element.
 */
function deleteUris(origId, hiddenId)
{
   // the 2 forms, the displayed list, and the hidden placeholder
   var orig    = $('#' + origId)[0];
   var hidden  = $('#' + hiddenId)[0];
   // all the checked URIs (check there is at least one)
   var checked = $(':checkbox:checked');
   if ( checked.length == 0 ) {
      alert('Error: No document nor directory selected.');
      return;
   }
   // for each of them...
   for ( var i = 0; i != checked.length; ++i ) {
      // the input field and its name
      var field = checked[i];
      var name  = field.name;
      if ( ! name.startsWith('delete-') ) {
         alert('Error: The checkbox ID is not starting with "delete-": ' + name);
         return;
      }
      if ( field.form.id != origId ) {
         alert('Error: The checkbox is not in the orig form: ' + field.form.id);
         return;
      }
      // get the value of the corresponding hidden field with the URI
      var num = name.substr('delete'.length);
      var value = orig.elements['name' + num].value;
      // create the new input field in the second form, to be submitted
      var input = document.createElement('input');
      input.setAttribute('name',  'uri-to-delete-' + (i + 1));
      input.setAttribute('type',  'hidden');
      input.setAttribute('value', value);
      // add the new field to the second form
      hidden.appendChild(input);
   }
   // submit the form
   hidden.submit();
};

/* ==== Profiler support ======================================================== */

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
   editorSetContent(jsonId, pretty);
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
   download(editorContent(jsonId), 'profile-report.json', 'application/json');
}

function download(text, name, type)
{
   var a = document.createElement('a');
   var b = new Blob([ text ], { type: type });
   a.href = URL.createObjectURL(b);
   a.download = name;
   a.click();
}

function profileImpl(queryId, endpoint, success)
{
   // the request content
   var fd = new FormData();
   fd.append('query',  editorContent(queryId));
   fd.append('target', $('#target-id').text());
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
   $('.prof-success').show();
}

/**
 * Display a stacktrace.
 *
 * @param st   The stacktrace to display, as a JSON object.
 * @param area The element where to display the stacktrace.
 */
function displayStackTrace(st, area)
{
   // the 'whereURI' of the frame where to stop (from the profiler itself)
   var stop  = '/profiler/profile-lib.xql';
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

function selectTarget(targetId, id, targetLabel, label)
{
   // set the ID on the hidden element
   $('#' + targetId).text(id);
   // set the label on the display button
   var btn = $('#' + targetLabel);
   btn.text(label);
   // toggle the class of the display button if necessary
   if ( btn.hasClass('btn-danger') ) {
      btn.removeClass('btn-danger');
      btn.addClass('btn-primary');
      // activate the 'profile' and 'as xml' buttons
      $('#go-profile').prop('disabled', false);
      $('#go-as-xml').prop('disabled', false);
   }
}
