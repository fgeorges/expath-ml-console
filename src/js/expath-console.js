"use strict";

// ensure the emlc global var
window.emlc = window.emlc || {};

(function() {

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

})();
