"use strict";

// ensure the emlc global var
window.emlc = window.emlc || {};

(function() {

    emlc.renderMarkdown = renderMarkdown;

    // return the dir part of a path (that is, minus filename if any)
    function dirname(path) {
        return path.match(/.*\//);
    }

    function highlight(code, lang) {
        var success = false;
        // "normalize" lang if 'sjs' or 'xqy'
        if ( lang === 'sjs' ) {
            lang = 'javascript';
        }
        else if ( lang === 'xqy' ) {
            lang = 'xquery';
        }
        // if lang is explicit
        if ( lang ) {
            try {
                hljs.highlight(lang, code).value;
                success = true;
            }
            catch ( err ) {
                console.log('Error highlighting lang ' + lang + ': ' + err);
            }
        }
        // if lang is implicit (or if there was an error above, fall back here)
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
    }

    function renderMarkdown(root, uri) {
        $(document).ready(function () {
            const dir      = dirname(uri);
            const renderer = new marked.Renderer();
            renderer.image = function(href, title, text) {
                return '<img src="' + root + 'bin?uri=' + dir + href + '"></img>';
            };
            marked.setOptions({
                highlight: highlight,
                renderer:  renderer
            });
            $('.md-content').each(function() {
                const elem = $(this);
                elem.html(marked(elem.text()));
            });
        });
    }

})();
