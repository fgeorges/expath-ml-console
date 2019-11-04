"use strict";

// ensure the emlc global var
window.emlc = window.emlc || {debug: {}};

(function() {

   // initialise the CXAN install form
   $(document).ready(function () {
      $("#cxan-install :input[name='repo']").change(cxanRepoChanges);
      var site = $("#cxan-install :input[name='std-website']");
      site.change(cxanWebsiteChanges);
      site.change();
   });

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

})();
