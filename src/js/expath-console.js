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
