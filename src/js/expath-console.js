"use strict";

//
// FIXME: TODO: Split this file in several files, and cherry-pick those to load
// for each page in the console.
//
// Profiler-specific code must go to a profile-specific JavaScript file.  Same
// for job-specific code.  As they both share quite some code, there must be a
// way to have common "libraries".
//
// Same for the ACE-related code, etc.  And for HTTP-related code (instead of
// using $.ajax()...)
//
// TODO: Instead of using alert(), use some temporary messages on the page,
// e.g. when saving a doc in a db.  Use a dismissable alert from Bootstrap 4:
// https://getbootstrap.com/docs/4.1/components/alerts/.
//
// TODO: Upgrade to Bootstrap 4?
//

// ensure the emlc global var
window.emlc = window.emlc || {};

/*~
 * Send a REST request to the CXAN website selected in the CXAN install form.
 *
 * @param endpoint The endpoint to send the request to.
 * 
 * @param callback The callback function to call when the XML response is
 * received from the REST service.
 */
function cxanRest(endpoint, callback)
{
   var site   = $("#cxan-install :input[name='std-website']").val();
   var domain = site == 'prod' ? 'http://cxan.org' : 'http://test.cxan.org';
   $.ajax({
      url: domain + endpoint,
      dataType: 'xml',
      headers: {
         accept: 'application/xml'
      }
   }).done(callback);
}

/*~
 * Handler for `change` event for field `std-website` of the CXAN install form.
 *
 * Remove all options on the field `repo`, send a REST request to CXAN to get the
 * list of all repositories in the new selected website, and add the new options
 * accordingly.
 */
function cxanWebsiteChanges()
{
   // remove the old repositories
   var repo = $("#cxan-install :input[name='repo']");
   $('option', repo).remove();
   // add the repositories for the new selected site
   cxanRest('/pkg', function(xml) {
      $(xml).find('id').each(function() {
         var id = $(this).text();
         repo.append($('<option>', { value : id }).text(id));
      });
      repo.change();
   });
}

/*~
 * Handler for `change` event for field `repo` of the CXAN install form.
 *
 * Remove all options on the field `pkg`, send a REST request to CXAN to get the
 * list of all packages in the new selected repo, and add the new options
 * accordingly.
 */
function cxanRepoChanges()
{
   // remove the old packages
   var pkg = $("#cxan-install :input[name='pkg']");
   $('option', pkg).remove();
   // add the packages for the new selected repo
   var repo = $(this).val();
   cxanRest('/pkg/' + repo, function(xml) {
      $(xml).find('abbrev').each(function() {
         var abbrev = $(this).text();
         pkg.append($('<option>', { value : repo + '/' + abbrev }).text(abbrev));
      });
   });
}

// initialise page components
$(document).ready(function () {
   // initialise the CXAN install form, if any
   $("#cxan-install :input[name='repo']").change(cxanRepoChanges);
   var site = $("#cxan-install :input[name='std-website']");
   site.change(cxanWebsiteChanges);
   site.change();
   // initialise the data tables
   $('.datatable').DataTable({
      info: false,
      paging: false,
      searching: false,
      // no initial oredering
      order: []
   });

   // TODO: Should be in the profiler dedicated JS file
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

   // dead code to remove, unless we want to use popovers again...
   // initialize popovers
   // $('[data-toggle="popover"]').popover({ html: true });
});

/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 * Browser support
 */

/*~
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
      var field  = checked[i];
      var name   = field.name;
      var parsed = /^delete-(doc|dir)-([0-9]+)$/.exec(name);
      if ( ! parsed ) {
         alert('Error: The checkbox ID is not matching "delete-xxx-nnn": ' + name);
         return;
      }
      if ( field.form.id != origId ) {
         alert('Error: The checkbox is not in the orig form: ' + field.form.id);
         return;
      }
      // get the value of the corresponding hidden field with the URI
      var type  = parsed[1];
      var num   = parsed[2];
      var value = orig.elements['name-' + num].value;
      // create the new input field in the second form, to be submitted
      var input = document.createElement('input');
      input.setAttribute('name',  type + '-to-delete-' + (i + 1));
      input.setAttribute('type',  'hidden');
      input.setAttribute('value', value);
      // add the new field to the second form
      hidden.appendChild(input);
   }
   // submit the form
   hidden.submit();
};

/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 * Profiler support
 */

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

/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 * Job support
 */

function jobCreate(codeId, detailId, timeId, countId, uriId, collId, dryId)
{
   $('.create-success').hide();
   var target = $('#target-id').text();
   if ( ! target ) {
      var msg = 'No target database or appserver selected!';
      alert(msg);
      throw new Error(msg);
   }
   var data   = new FormData();
   data.append('code',   elmc.editorContent(codeId));
   data.append('lang',   $('input[name=lang]:checked').val());
   data.append('target', target);
   var url = '/api/job/create';
   if ( $('#' + dryId).is(':checked') ) {
      url += '?dry=true';
   }
   fetch(url, {
      credentials: 'same-origin',
      method: 'post',
      body: data
   })
   .then(function(resp) {
      if ( ! resp.ok ) {
         const msg = 'Job creation service response was not ok: '
             + resp.status + ' - ' + resp.statusText;
	 resp.text().then(function(text) {
            console.log(text);
	 });
         alert(msg);
         throw new Error(msg);
      }
      return resp.json();
   })
   .then(function(data) {
      var link = function(id, val) {
	 var uri  = $('#' + id);
	 var dad  = uri.parent();
	 var href = dad.data('href');
	 uri.text(val);
	 dad.attr('href', href + val);
      };
      link(uriId,  data.job.uri);
      link(collId, data.job.coll);
      $('#' +  timeId).text(data.time);
      $('#' + countId).text(data.tasks.length);
      var table = $('#' + detailId).DataTable();
      var href  = $('#' + uriId).parent().data('href');
      table.clear();
      data.tasks.forEach(function(task) {
         table.row.add(
	    $('<tr>')
	       .append($('<td>').text(task.num))
	       .append($('<td>').text(task.created))
	       .append($('<td>').text(task.label))
	       .append($('<td>')
		  .append($('<a>').attr('href', href + task.uri)
	             .append($('<code>').addClass('doc').text(task.uri))))
         );
      });
      table.columns.adjust().draw();
      // some "width: 0" messes up the table display on Firefox
      $('#create-detail').width('');
      $('.create-success').show();
   });
}

// createId and taskId are the IDs of the editors for the code
function jobStart(codeId, collId)
{
   var data = new FormData();
   data.append('code', emlc.editorContent(codeId));
   var id  = $('#' + collId).text().slice(6);
   var url = '/api/job/' + id + '/start';
   fetch(url, {
      credentials: 'same-origin',
      method: 'post',
      body: data
   })
   .then(function(resp) {
      if ( ! resp.ok ) {
         const msg = 'Job starting service response was not ok: '
             + resp.status + ' - ' + resp.statusText;
	 resp.text().then(function(text) {
            console.log(text);
	 });
         alert(msg);
         throw new Error(msg);
      }
      return resp.json();
   })
   .then(function(data) {
      console.dir(data);
      alert('Job started: #' + id);
   });
}
