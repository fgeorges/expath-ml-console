"use strict";

// ensure the emlc global var
window.emlc = window.emlc || {};

(function() {

   const langtools = ace.require('ace/ext/language_tools');
   const highlight = ace.require('ace/ext/static_highlight');

   emlc.saveDoc          = saveDoc;
   emlc.deleteDoc        = deleteDoc;
   emlc.editorContent    = editorContent;
   emlc.editorSetContent = editorSetContent;

   // initialize code snippets and editors
   $(document).ready(function () {
      $('.code').each(initCodeSnippet);
      $('.editor').each(initCodeEditor);
   });

   // init ACE, does not need to wait for page being loaded
   initAce();

   /*~ Contains all editors on the page, by ID. */
   emlc.editors = {};

   /*~
    * Init a (read-only) code snippet on the page.
    */
   function initCodeSnippet() {
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

   /*~
    * Init a code editor on the page.
    */
   function initCodeEditor() {
      var elem = $(this);
      var e    = {};
      e.id     = elem.attr('id');
      e.uri    = elem.attr('ace-uri');
      e.top    = elem.attr('ace-top');
      e.theme  = elem.attr('ace-theme');
      e.mode   = elem.attr('ace-mode');
      e.editor = ace.edit(elem.get(0));
      e.editor.setTheme(e.theme);
      e.editor.getSession().setMode(e.mode);
      e.editor.setOption('enableBasicAutocompletion', true);
      e.editor.setOption('enableLiveAutocompletion',  true);
      e.editor.setOption('enableSnippets',            true);
      emlc.editors[e.id] = e;
   }

   /*~
    * Add completer for Marklogic functions to ACE.
    */
   function initAce() {
      langtools.addCompleter({
         getCompletions: function(editor, session, pos, prefix, callback) {
            let results = [];
            const mode = session.getMode().$id;
            if ( mode === 'ace/mode/javascript' ) {
               const token = session.getTokenAt(pos.row, pos.column);
               if ( token && token.type === 'identifier' ) {
                  const forPrefix = function() {
                     if ( /^[a-z2]$/.test(token.value) ) {
                        results = emlc.acePrefixesSjs;
                     }
                  };
                  if ( token.index < 2 ) {
                     forPrefix();
                  }
                  else {
                     const tokens = session.getTokens(pos.row);
                     const dot    = tokens[token.index - 1];
                     const prefix = tokens[token.index - 2];
                     if ( dot.type === 'punctuation.operator' && dot.value === '.' && prefix.type === 'identifier' ) {
                        results = emlc.aceFunctionsSjs[prefix.value];
                     }
                     else {
                        forPrefix();
                     }
                  }
               }
            }
            else if ( mode === 'ace/mode/xquery' ) {
               const token = session.getTokenAt(pos.row, pos.column);
               if ( token && token.type === 'support.function' ) {
                  const tok = token.value;
                  if ( tok.length === prefix.length ) {
                     if ( /^[a-z2]$/.test(tok) ) {
                        results = emlc.acePrefixesXqy;
                     }
                  }
                  else {
                     const parts = tok.split(':');
                     if ( parts.length === 2 ) {
                        results = emlc.aceFunctionsXqy[parts[0]];
                     }
                  }
               }
            }
            callback(null, results);
         }
         // getDocTooltip: function(item) {
         //     item.docHTML = '<b>Foobar</b><hr></hr><em>Blabla</em>';
         // }
      });
   }

   // id is the id of the ACE editor element
   // type is either 'xml' or 'text'
   function saveDoc(id, type) {
      // get the ACE doc
      var info     = emlc.editors[id];
      var endpoint = info.top + 'save-' + type;
      // the request content
      var fd = new FormData();
      fd.append('doc', emlc.editorContent(id));
      fd.append('uri', info.uri);
      // the message alert
      var msg = function(status, title, message) {
         var template = $('#' + id + '-message');
         var alert    = template.clone();
         alert.children('strong').text(title);
         alert.children('span').text(message);
         alert.addClass('show alert-' + status);
         alert.insertBefore(template);
         alert.show();
         if ( status === 'success' ) {
            // if success, auto-dismiss after 4 secs
            alert.delay(4000).slideUp(500, function() {
               $(this).alert('close');
            });
         }
      };
      // the request itself
      $.ajax({
         url: endpoint,
         method: 'POST',
         data: fd,
         dataType: 'text',
         processData: false,
         contentType: false,
         success: function(data) {
            msg('success', '', data);
         },
         error: function(xhr, status, error) {
            msg('danger', 'Error: ', status + ' (' + error + ') - See logs for details.');
         }});
   }

   // id is the id of the ACE editor element
   function deleteDoc(id) {
      $('#' + id + '-delete').submit();
   }

   function editorDocument(id) {
      var info = emlc.editors[id];
      if ( info ) {
         var editor = info.editor;
         if ( editor ) {
            var session = editor.getSession();
            if ( session ) {
               return session.getDocument();
            }
         }
      }
   }

   function editorContent(id) {
      var doc = editorDocument(id);
      if ( doc ) {
         return doc.getValue();
      }
   }

   function editorSetContent(id, value) {
      var doc = editorDocument(id);
      if ( doc ) {
         doc.setValue(value);
      }
   }

})();
