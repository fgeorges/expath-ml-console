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

// ensure the emlc global var
window.emlc = window.emlc || {};

// initialise page components
$(document).ready(function () {

   // TODO: Shouldn't this be in a datatable specific JS file?
   // initialise the data tables
   $('.datatable').DataTable({
      info: false,
      paging: false,
      searching: false,
      // no initial oredering
      order: []
   });

   // dead code to remove, unless we want to use popovers again...
   // initialize popovers
   // $('[data-toggle="popover"]').popover({ html: true });
});

function initMarked(dbpath, uri)
{
   $(document).ready(function () {
      var renderer = new marked.Renderer();
      renderer.image = function(href, title, text) {
         return '<img src="' + dbpath + 'bin?uri=' + uri + href + '"></img>';
      };
      marked.setOptions({
         highlight: function(code) {
            return hljs.highlightAuto(code).value;
         },
         renderer: renderer
      });
      $('.md-content').each(function() {
         var elem = $(this);
         elem.html(marked(elem.text()));
      });
   });
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
