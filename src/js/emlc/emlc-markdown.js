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
        try {
            return lang
                ? hljs.highlight(lang, code).value
                : hljs.highlightAuto(code).value;
        }
        catch ( err ) {
            console.log('Error highlighting lang ' + lang + ': ' + err);
            console.log('Please report this to http://github.com/fgeorges/expath-ml-console.');
            return code.replace(/&/g, '&amp;').replace(/</g, '&lt;');
        }
    }

    // format a MD code block (given as a `token`, add the result to `elem`)
    // TODO: Support SPARQL as well (with prefixes from target DB?)
    function codeBlock(elem, token) {
        // the pre element with the highlighted code
        const pre  = $('<pre>');
        const span = $('<span>');
        const code = $('<code>');
        // "normalize" lang if 'js', 'sjs' or 'xqy'
        const lang = token.lang === 'js' || token.lang === 'sjs'
            ? 'javascript'
            : token.lang === 'xqy'
            ? 'xquery'
            : token.lang;
        // if no lang, should we try to infer it from, say, the first line to be
        // `xquery version "3.0";` or `"use strict"`?
        if ( lang ) {
            code.addClass('lang-' + lang);
        }
        const rich = highlight(token.text, lang);
        code.html(rich);
        span.text(token.lang);
        pre.append(span);
        pre.append(code);
        elem.append(pre);
        if ( lang === 'javascript' || lang === 'xquery' ) {
            // add input elements for the params, returns their ID
            const params = codeParams(elem, token.text, lang, rich);
            // the "target database" selection widget
            const widget = $('#emlc-db-widget-template')
                .clone()
                .children()
                .addClass('emlc-target-widget')
                .data('lang',   lang)
                .data('params', params.join(','))
                .data('code',   token.text);
            emlc.targetInitWidget(widget);
            elem.append(widget);
        }
    };

    function randomId(len) {
        if ( ! len ) {
            len = 16;
        }
        const a = [];
        for ( let i = 0; i < len; ++i ) {
            // 97 = 'a', 26 = alphabet length
            const n = Math.floor((Math.random() * 26) + 97);
            a.push(String.fromCharCode(n));
        }
        return a.join('');
    }

    function codeParams(elem, text, lang, rich) {
        const params = lang === 'xquery' ? codeParamsXqy(rich) : codeParamsJs(rich);
        const ids    = [];
        params.forEach(function(p) {
            const id = randomId();
            ids.push(id);
            const title = p.type ? `${p.label} as ${p.type}` : p.label;
            const type  = p.type       ? `data-param-type="${p.type}"` : '';
            const occur = p.occurrence ? `data-param-occurrence="${p.occurrence}"` : '';
            // TODO: Make <RET> on these fields to behave like clicking on the "execute" button.
            // (possible here by using jQuery to add the listener straight away, and use click()
            // directly on the button itself...?)
            elem.append($(`
                <div class="form-group row">
                  <label class="col-sm-2 col-form-label" title="${title}">${p.label}</label>
                  <div class="col-sm-10">
                    <input type="text" class="form-control" id="${id}" title="${title}"
                           data-param-name="${p.name}" data-param-label="${p.label}" ${type} ${occur}>
                  </div>
                </div>`));
        });
        return ids;
    }

    const parser = {
        next: function(tok) {
            if ( ! tok ) { return; }
            return tok.nextSibling;
        },
        isText: function(tok) {
            if ( ! tok ) { return; }
            return tok.nodeName === '#text';
        },
        isWs: function(tok) {
            if ( ! tok ) { return; }
            return parser.isText(tok) && /^\s+$/.test(tok.textContent);
        },
        isSpan: function(tok, name) {
            if ( ! tok ) { return; }
            return tok.nodeName === 'SPAN'
                && tok.attributes.class
                && tok.attributes.class.textContent === ('hljs-' + name);
        },
        isComment: function(tok) {
            return parser.isSpan(tok, 'comment');
        },
        isKeyword: function(tok, name) {
            return parser.isSpan(tok, 'keyword') && tok.innerText === name;
        },
        isLiteral: function(tok) {
            return parser.isSpan(tok, 'literal');
        }
    };

    function codeParamsJs(html) {
        const params = [];
        const nextComment = function(tok) {
            if ( ! tok ) { return; }
            if ( parser.isComment(tok) ) {
                return tok;
            }
            return nextComment(parser.next(tok));
        };
        const doComment = function(tok) {
            const lines = [];
            if ( tok.textContent.startsWith('/*') ) {
                tok.textContent.slice(3, -2).split(/\n|\r/).forEach(function(line) {
                    const m = /^\s*\*\s*/.exec(line);
                    if ( m ) {
                        line = line.slice(m[0].length);
                    }
                    lines.push(line.trim());
                });
            }
            else {
                lines.push(tok.textContent.slice(3).trim());
            }
            lines.forEach(function(line) {
                const args = line.slice(7).split(/\s+/).filter(function(s) { return s; });
                if ( line.startsWith('@params') ) {
                    if ( params.seenParams ) {
                        console.log('ERROR: cannot have @params several times');
                    }
                    if ( params.length ) {
                        console.log('ERROR: cannot have @params mixed with @param');
                    }
                    if ( ! args.length ) {
                        console.log('ERROR: arguments mandatory for @params');
                    }
                    params.seenParams = true;
                    args.forEach(function(arg) { params.push({
                        name:  arg,
                        label: arg
                    }); });
                }
                else if ( line.startsWith('@param') ) {
                    if ( params.seenParams ) {
                        console.log('ERROR: cannot have @params mixed with @param');
                    }
                    if ( ! args.length ) {
                        console.log('ERROR: arguments mandatory for @param');
                    }
                    const p = {
                        name:  args[0],
                        label: args[0]
                    };
                    args.slice(1).forEach(function(arg) {
                        if ( arg.startsWith('as:') ) {
                            p.type = arg.slice(3).replace('.', ':');
                        }
                        else if ( arg.startsWith('select:') ) {
                            console.log(`ERROR: @param select:* argument not supported yet: ${arg}`);
                        }
                        else {
                            console.log(`ERROR: unknown @param argument: ${arg}`);
                        }
                    });
                    params.push(p);
                }
            });
            return parser.next(tok);
        };
        // loop as long as we have "top-level" comments
        const parse = function(tok) {
            if ( ! tok ) { return; }
            tok = nextComment(tok);
            if ( ! tok ) { return; }
            tok = doComment(tok);
            parse(tok);
        };
        // make actual nodes out of the output of hljs
        const tokens = $.parseHTML(html);
        // parse the tokens
        parse(tokens[0]);
        return params;
    }

    // parse the XQuery code for namespace and variable declarations, based on
    // the hljs output, used as a poor man's lexer
    function codeParamsXqy(html) {
        // parsing util functions
        const varName = function(tok) {
            if ( parser.isSpan(tok, 'variable') && tok.innerText[0] === '$' ) {
                return tok.innerText.slice(1);
            }
        };
        const nextDecl = function(tok) {
            if ( ! tok ) { return; }
            if ( parser.isKeyword(tok, 'declare') ) {
                return tok;
            }
            return nextDecl(parser.next(tok));
        };
        const declType = function(tok) {
            const n = parser.next(tok);
            if ( n.nodeName !== '#text' ) { return; }
            if ( /^\s+variable\s+$/.test(n.textContent) ) {
                return 'variable';
            }
            else if ( parser.isWs(n) && parser.isKeyword(parser.next(n), 'namespace') ) {
                return 'namespace';
            }
        };
        // the variables to accumulate the variable and namespace declarations
        const vars = [];
        const nses = {};
        // "eat" a variable declaration (only external vars are captured)
        const doVar = function(tok) {
            const v = {};
            tok = parser.next(parser.next(tok)); // ignore "declare" and " variable "
            if ( ! tok ) { return; }
            v.name = varName(tok);
            if ( ! v.name ) { return tok; }
            tok = parser.next(tok);
            if ( ! parser.isText(tok) ) { return tok; }
            const match = /^(:[_a-zA-Z][-_.0-9a-zA-Z]*)?\s+(external\s*;)?/.exec(tok.textContent);
            if ( ! match ) { return tok; }
            if ( match[1] ) {
                v.prefix = v.name;
                v.name   = match[1].slice(1);
            }
            if ( ! match[2] ) {
                tok = parser.next(tok);
                if ( ! parser.isKeyword(tok, 'as') ) { return tok; }
                tok = parser.next(tok);
                if ( parser.isWs(tok) ) {
                    tok = parser.next(tok);
                    if ( ! parser.isLiteral(tok) ) { return tok; }
                    v.type = tok.innerText
                    tok = parser.next(tok);
                    if ( ! parser.isText(tok) ) { return tok; }
                    const occur = /^\s*([?+*])?\s*external\s*;/.exec(tok.textContent);
                    if ( ! occur ) { return tok; };
                    if ( occur[1] ) {
                        v.occurrence = occur[1];
                    }
                }
                else {
                    // for non xs: types - " sem:iri+ external; ..."
                    const match = /^\s+([_a-zA-Z][-_.0-9a-zA-Z]*):([_a-zA-Z][-_.0-9a-zA-Z]*)\s*([?+*])?\s*external\s*;/
                        .exec(tok.textContent);
                    if ( ! match ) { return tok; }
                    v.type = match[1] + ':' + match[2];
                    if ( match[3] ) {
                        v.occurrence = match[3];
                    }
                }
            }
            vars.push(v);
            return parser.next(tok);
        };
        // "eat" a namespace declaration
        const doNs = function(tok) {
            tok = parser.next(parser.next(parser.next(tok))); // ignore "declare", " " and "namespace"
            if ( ! parser.isText(tok) ) { return tok; }
            const match = /^\s+([_a-zA-Z][-_.0-9a-zA-Z]*)\s*=\s*$/.exec(tok.textContent);
            if ( ! match ) { return tok; }
            const prefix = match[1];
            tok = parser.next(tok);
            if ( ! parser.isSpan(tok, 'string') ) { return; }
            const quote = tok.innerText.slice(0, 1);
            if ( quote !== '"' && quote !== "'" ) { return; }
            if ( quote !== tok.innerText.slice(-1) ) { return; }
            const uri = tok.innerText.slice(1, -1);
            tok = parser.next(tok);
            if ( ! parser.isText(tok) ) { return tok; }
            if ( ! /^\s*;/.test(tok.textContent) ) { return tok; };
            nses[prefix] = uri;
            return parser.next(tok);
        };
        // loop as long as we have "declare" statements
        const parse = function(tok) {
            if ( ! tok ) { return; }
            const decl = nextDecl(tok);
            if ( ! decl ) { return; }
            var   here = parser.next(decl);
            const type = declType(decl);
            if ( type === 'variable' ) {
                here = doVar(decl);
            }
            else if ( type === 'namespace' ) {
                here = doNs(decl);
            }
            parse(here);
        };
        // make actual nodes out of the output of hljs
        const tokens = $.parseHTML(html);
        // parse the tokens
        parse(tokens[0]);
        return vars.map(function(v) {
            const res = {
                type: v.type
            };
            if ( v.prefix ) {
                res.name  = '{' + nses[v.prefix] + '}' + v.name;
                res.label = v.prefix + ':' + v.name;
            }
            else {
                res.name  = '{}' + v.name;
                res.label = v.name;
            }
            if ( v.occurrence ) {
                res.occurrence = v.occurrence;
            }
            return res;
        });
    }

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
