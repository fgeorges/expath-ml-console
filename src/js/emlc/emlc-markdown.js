"use strict";

// ensure the emlc global var
window.emlc = window.emlc || {};

(function() {

    emlc.renderMarkdown = renderMarkdown;

    function renderMarkdown(root, uri) {
        $(document).ready(function () {
            var renderer = new marked.Renderer();
            renderer.image = function(href, title, text) {
                return '<img src="' + root + 'bin?uri=' + uri + href + '"></img>';
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
