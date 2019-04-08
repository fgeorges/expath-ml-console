"use strict";

// ensure the emlc global var
window.emlc = window.emlc || {};

(function() {

    emlc.renderMarkdown = renderMarkdown;

    function renderMarkdown(root, uri) {
        $(document).ready(function () {
            const renderer = new marked.Renderer();
            renderer.image = function(href, title, text) {
                return '<img src="' + root + 'bin?uri=' + uri + href + '"></img>';
            };
            marked.setOptions({
                highlight: function(code, lang) {
                    var success = false;
                    if ( lang ) {
                        try {
                            hljs.highlight(lang, code).value;
                            success = true;
                        }
                        catch ( err ) {
                            console.log('Error highlighting lang ' + lang + ': ' + err);
                        }
                    }
                    if ( ! success ) {
                        try {
                            hljs.highlightAuto(code).value;
                        }
                        catch ( err ) {
                            const msg = 'Error highlighting lang ' + lang + ': ' + err;
                            console.log(msg);
                            alert(msg + '\nPlease report this to'
                                  + ' http://github.com/fgeorges/expath-ml-console.'
                                  + '\nMore info in the browser console logs.');
                            throw err;
                        }
                    }
                },
                renderer: renderer
            });
            $('.md-content').each(function() {
                const elem = $(this);
                elem.html(marked(elem.text()));
            });
        });
    }

})();
