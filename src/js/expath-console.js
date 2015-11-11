var high = ace.require("ace/ext/static_highlight");
var dom  = ace.require("ace/lib/dom");

// TODO: Replace by jQuery?
function qsa(sel)
{
   return Array.apply(null, document.querySelectorAll(sel));
}

qsa(".code").forEach(function (code) {
   high(
      code,
      {
         mode: code.getAttribute("ace-mode"),
         theme: code.getAttribute("ace-theme"),
         startLineNumber: 1,
         showGutter: code.getAttribute("ace-gutter"),
         trim: false
      },
      function (highlighted) {
      });
});

// contains all editors on the page, by ID
var editors = {};

qsa(".editor").forEach(function (edElm) {
   var e = {};
   e.id     = edElm.getAttribute("id");
   e.uri    = edElm.getAttribute("ace-uri");
   e.top    = edElm.getAttribute("ace-top");
   e.theme  = edElm.getAttribute("ace-theme");
   e.mode   = edElm.getAttribute("ace-mode");
   e.editor = ace.edit(edElm);
   e.editor.setTheme(e.theme);
   e.editor.getSession().setMode(e.mode);
   editors[e.id] = e;
});

// id is the id of the ACE editor element
// type is either "xml" or "text"
function saveDoc(id, type)
{
   // get the ACE doc
   var info     = editors[id];
   var endpoint = info.top + "save-" + type;
   // the request content
   var fd = new FormData();
   fd.append("doc", editorContent(id));
   fd.append("uri", info.uri);
   // the request itself
   $.ajax({
      url: endpoint,
      method: "POST",
      data: fd,
      dataType: "text",
      processData: false,
      contentType: false,
      success: function(data) {
         alert("Success: " + data);
      },
      error: function(xhr, status, error) {
         alert("Error: " + status + " (" + error + ")\n\nSee logs for details.");
      }});
};

// id is the id of the ACE editor element
function deleteDoc(id)
{
   $("#" + id + "-delete").submit();
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

/**
 * Delete all selected URIs.
 *
 * There are 2 forms (with the ID origId and hiddenId resp.)  The original form
 * is the list of URIs displayed to the user.  The hidden form is a form used to
 * implement the solution.
 *
 * This code goes through all checked checkboxes in the first form (the URIs are
 * displayed each with a checkbox).  They all have a name of the form "delete-1",
 * "delete-2", etc., and must each have a corresponding form text field with
 * name "name-1", "name-2", etc., with the corresponding URI.
 *
 * For each of the checked checkbox, a text field is created in the hidden form,
 * with the name "uri-to-delete-1", "uri-to-delete-2", etc.  The hidden form is
 * then submitted.
 *
 * @param origId    The id of the original form element.
 * @param hiddenId  The id of the hidden form element.
 */
function deleteUris(origId, hiddenId)
{
   // the 2 forms, the displayed list, and the hidden placeholder
   var orig    = $("#" + origId)[0];
   var hidden  = $("#" + hiddenId)[0];
   // all the checked URIs (check there is at least one)
   var checked = $(":checkbox:checked");
   if ( checked.length == 0 ) {
      alert("Error: No document nor directory selected.");
      return;
   }
   // for each of them...
   for ( var i = 0; i != checked.length; ++i ) {
      // the input field and its name
      var field = checked[i];
      var name  = field.name;
      if ( ! name.startsWith("delete-") ) {
         alert("Error: The checkbox ID is not starting with 'delete-': " + name);
         return;
      }
      if ( field.form.id != origId ) {
         alert("Error: The checkbox is not in the orig form: " + field.form.id);
         return;
      }
      // get the value of the corresponding hidden field with the URI
      var num = name.substr("delete".length);
      var value = orig.elements["name" + num].value;
      // create the new input field in the second form, to be submitted
      var input = document.createElement("input");
      input.setAttribute("name",  "uri-to-delete-" + (i + 1));
      input.setAttribute("type",  "hidden");
      input.setAttribute("value", value);
      // add the new field to the second form
      hidden.appendChild(input);
   }
   // submit the form
   hidden.submit();
};
