"use strict";

declareUpdate();

const t   = require('/lib/tools.xqy');
const v   = require('/lib/view.xqy');
const lib = require('./lib-init.xqy');

const urlBase  = 'http://localhost:8000/common/codemirror5/addon/hint/';
const urlDocs  = urlBase + 'marklogic-hint-docs.json';
const urlTypes = urlBase + 'marklogic-hint-types.json';

function get(url, user, pwd) {
    const resp = xdmp.httpGet(url, { authentication: { username: user, password: pwd }});
    const info = fn.head(resp);
    if ( info.code !== 200 ) {
        xdmp.dir(resp);
        throw new Error(`MarkLogic responded ${info.code} for ${url}`);
    }
    return fn.head(fn.tail(resp)).toObject();
}

function insert(uri, node) {
    // TODO: Set permissions properly.
    xdmp.documentInsert(uri, node);
}

function insertJs(uri, name, obj) {
    const js = `"use strict";

// ensure the emlc global var
window.emlc = window.emlc || {};

emlc.${name} = ${JSON.stringify(obj)};
`;
    insert(uri, new NodeBuilder().addText(js).toNode());
}

/*
 *    {
 *       $: [
 *        { caption: 'node',    value: 'node()',    meta: 'type' },
 *        { caption: 'element', value: 'element()', meta: 'type' },
 *        ...
 *      ],
 *      map: [
 *        { caption: 'map', value: 'map', meta: 'type' },
 *      ],
 *      ...
 *    }
 */
function makeTypes(lang, suffix, sep, types) {
    const res = {};
    types.forEach(type => {
        const tokens = type.split(sep);
        const prefix = tokens[1] ? (tokens[0] === 'xf' ? 'xs' : tokens[0]) : '$';
        const name   = tokens[1] ? tokens[1] : tokens[0];
        if ( ! res[prefix] ) {
            res[prefix] = [];
        }
        res[prefix].push({
            caption: name,
            value:   prefix === '$' && lang === 'xqy' ? name + '()' : name,
            meta:    'type'
        });
    });
    insertJs(lib.typesUri + lang + '.js', 'aceTypes' + suffix, res);
}

/*
 *    [
 *      { caption: 'admin', value: 'admin:', meta: 'prefix' },
 *      { caption: 'alert', value: 'alert:', meta: 'prefix' },
 *      ...
 *    ]
 */
function makePrefixes(lang, suffix, sep, docs) {
    insertJs(
        lib.prefixesUri + lang + '.js',
        'acePrefixes' + suffix,
        Object.keys(docs.xquery).map(p => ({
            caption: p,
            value:   p + sep,
            meta:    'prefix'
        })));
}

/*
 *    {
 *      "admin": [{
 *          caption: 'foo',
 *          snippet: 'foo()',
 *          meta: '\u03bb'
 *        }, {
 *          caption: 'bar',
 *          snippet: 'bar(${1:one}, ${2:two}, ${3:three})',
 *          meta: '\u03bb'
 *        },
 *        ...
 *      ],
 *      "xdmp": [
 *        ...
 *      ]
 *    }
 */
function makeFunctions(lang, suffix, docs) {
    const res = {};
    Object.keys(docs).forEach(prefix => {
        const slot = docs[prefix];
        res[prefix] = Object.keys(slot).map(name => {
            const fun  = slot[name];
            const args = fun.params
                ? fun.params.map((p, i) => '${' + (i + 1) + ':' + p.name + '}').join(', ')
                : '';
            return {
                caption: name,
                snippet: name + '(' + args + ')',
                meta:    '\u03bb'
            };
        });
    });
    insertJs(lib.functionsUri + lang + '.js', 'aceFunctions' + suffix, res);
}

const user = t.mandatoryField('user');
const pwd  = t.mandatoryField('password');

// the type scripts
const inTypes = get(urlTypes, user, pwd);
makeTypes('sjs', 'Sjs', '.', inTypes.javascript);
makeTypes('xqy', 'Xqy', ':', inTypes.xquery);

// the prefix and function scripts
const inDocs = get(urlDocs, user, pwd);
makePrefixes('sjs', 'Sjs', '.', inDocs);
makePrefixes('xqy', 'Xqy', ':', inDocs);
makeFunctions('sjs', 'Sjs', inDocs.javascript);
makeFunctions('xqy', 'Xqy', inDocs.xquery);

// the config file itself
insert(lib.configUri, lib.makeConfig());
v.redirect('init');
