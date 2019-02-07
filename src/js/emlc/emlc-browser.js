"use strict";

// ensure the emlc global var
window.emlc = window.emlc || {};

(function() {

   emlc.deleteUris = deleteUris;

   // initialize the jQuery File Upload widget
   $(document).ready(function () {
      $('#fileupload').fileupload({
         url: '../../loader/upload'
      });

      // event handler to set the additional input fields
      $('#fileupload').bind('fileuploadsubmit', function(evt, data) {
         // the input elements
         const inputs  = data.context.find(':input');
         // missing any required value?
         const missing = inputs.filter(function() {
            return ! ( this.value || ! $(this).prop('required') );
         }).first().focus();
         if ( missing.length ) {
            data.context.find('button').prop('disabled', false);
            return false;
         }
         // set the form data from the input elements
         data.formData = inputs.serializeArray();
         // set the content type based on format
         const format = inputs.filter('[name="format"]').val();
// **********
// TODO: Set the file content type from the input selection (xml/text/binary/json)
//    - xml    -> application/xml
//    - text   -> text/plain
//    - binary -> application/octet-stream
//    - json   -> application/json
// A bit of a hack, but will be parsed properly on ML-side.  What about HTML?
// **********
      });
   });

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
   }

})();
