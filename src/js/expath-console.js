"use strict";

// ensure the emlc global var
window.emlc = window.emlc || {};

(function() {

   emlc.initMarked = initMarked;

   // initialise page components
   $(document).ready(function () {
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
            highlight: function(code, lang) {
               return lang
                  ? hljs.highlight(lang, code).value
                  : hljs.highlightAuto(code).value;
            },
            renderer: renderer
         });
         $('.md-content').each(function() {
            var elem = $(this);
            elem.html(marked(elem.text()));
         });
      });
   }

})();
