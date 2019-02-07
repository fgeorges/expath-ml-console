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
