"use strict";

// ensure the emlc global var
window.emlc = window.emlc || {};

(function() {

    emlc.renderMarkdown = renderMarkdown;

    // return the dir part of a path (that is, minus filename if any)
    function dirname(path) {
        return path.match(/.*\//);
    }

    // highlight some `code` (as text) with an optional `lang`, returns HTML (as text)
    function highlight(code, lang) {
        // if lang is explicit
        if ( lang ) {
            try {
                return hljs.highlight(lang, code).value;
            }
            catch ( err ) {
                console.log('Error highlighting lang ' + lang + ': ' + err);
            }
        }
        // if lang is implicit (or if there was an error above, fall back here)
        try {
            return hljs.highlightAuto(code).value;
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

    // format a MD code block (given as a `token`, add the result to `elem`)
    // TODO: Support SPARQL as well (with prefixes from target DB?)
    function codeBlock(elem, token) {
        // the pre element with the highlighted code
        const pre  = $('<pre>');
        const code = $('<code>');
        // "normalize" lang if 'sjs' or 'xqy'
        const lang = token.lang === 'sjs'
            ? 'javascript'
            : token.lang === 'xqy'
            ? 'xquery'
            : token.lang;
        if ( lang ) {
            code.addClass('lang-' + lang);
        }
        const rich = highlight(token.text, lang);
        code.html(rich);
        pre.append(code);
        if ( lang === 'javascript' || lang === 'xquery' ) {
            // the "target database" selection widget
            const widget = $('#emlc-db-widget-template')
                .clone()
                .children()
                .addClass('emlc-target-widget')
                .data('lang', lang)
                .data('code', token.text);
            emlc.targetInitWidget(widget);
            // append them all
            elem.append(pre);
            elem.append(widget);
        }
    };

    // The main function to enrich an element with content from MD tokens.
    //
    // Handle code blocks specially by:
    // - accumulate tokens, up to any code block token
    // - parse and "draw" them
    // - deal with the code block if any
    function enrich(elem, tokens, acc) {
        // an array to accumulate tokens, up to any code block token
        // (needed because links need to "travel" with the array)
        const newacc = function(t) {
            const a = [];
            a.links = t.links;
            return a;
        };
        // convert accumulated tokens to HTML, and append to `elem`
        const draw = function(acc) {
            if ( acc.length ) {
                const html = marked.parser(acc);
                elem.append($(html));
            }
        };
        // initial caller does not make `acc`
        if ( ! acc ) {
            acc = newacc(tokens);
        }
        // flush a last time if it is the end
        if ( ! tokens.length ) {
            draw(acc);
            return;
        }
        // use next token: if code flush tokens and draw code, or keep accumulating
        const tok = tokens.shift();
        if ( tok.type === 'code' ) {
            draw(acc);
            codeBlock(elem, tok);
            acc = newacc(tokens);
        }
        else {
            acc.push(tok);
        }
        // recurse on tokens
        enrich(elem, tokens, acc);
    };

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
                const elem   = $(this);
                const tokens = marked.lexer(elem.text());
                elem.empty();
                enrich(elem, tokens);
            });
        });
    }

})();
