"use strict";

/*~
 * This is a quite generic eval endpoint.
 *
 * @param code - The JavaScript or XQuery code, as text.
 * @param lang - Either 'javascript' or 'xquery'.
 * @param target - The database or server to evaluate against (ID or name).
 *
 * The result of evaluating the code is returned as a JSON array of objects in
 * which each result is enriched with info about its type.
 *
 * TODO: Support query parameters to pass from the client.
 * TODO: Handle errors from evaluating the query.
 * TODO: Support update queries.
 * TODO: Add the document URI for nodes?  To allow browsing.
 * TODO: Return the result of a SPARQL query in a specific (tabular) way?
 */

const a = require('/lib/admin.xqy');
const t = require('/lib/tools.xqy');

// global params
const code   = fn.exactlyOne(t.mandatoryField('code'));
const lang   = fn.exactlyOne(t.mandatoryField('lang'));
const target = fn.exactlyOne(t.mandatoryField('target'));

if ( lang !== 'javascript' && lang !== 'xquery' ) {
    t.error('wrong-param', 'The param lang is neither javascript nor xquery: ' + lang);
}

// get the actual target
const db = t.databaseExists(target);
const as = t.appserverExists(target);

if ( db && as ) {
    t.error('wrong-param', 'Target matches both database and appserver: ' + target);
}
else if ( ! db && ! as ) {
    t.error('wrong-param', 'Target does not exist: ' + target);
}

// the options for eval()
const fun     = lang === 'javascript' ? xdmp.eval : xdmp.xqueryEval;
const options = {};
if ( db ) {
    options.database = db;
}
else {
    options.database = xdmp.serverDatabase(as);
    options.modules  = xdmp.serverModulesDatabase(as);
    options.root     = xdmp.serverRoot(as);
}

// the query parameters
const params = {
    // TODO: Support parameters...
};

// do it
const start = xs.dateTime(new Date());
const res   = fun(code, params, options);
const end   = xs.dateTime(new Date());

// format the result
const resp = {
    input: {
        target: target,
        lang: lang,
        code: code,
        database: db,
        server: as,
        options: options
    },
    time: {
        eval: end.subtract(start)
    },
    result: []
};

// map between constructor name and node kind
const nodes = {
    ArrayNode: 'array-node()',
    BinaryNode: 'binary-node()',
    BooleanNode: 'boolean-node()',
    NullNode: 'null-node()',
    NumberNode: 'number-node()',
    ObjectNode: 'object-node()',
    Attr: 'attribute()',
    Comment: 'comment()',
    Document: 'document-node()',
    Element: 'element()',
    Node: 'node()',
    ProcessingInstruction: 'processing-instruction()',
    Text: 'text()'
};

// FIXME: When evaluating XQuery, 42 will result in "number" below, and 'foobar'
// to "string", as if they were their JavaScript equivalent (probably caused by
// the mapping for simple types being "transparent", or "invisible" on the
// JavaScript side of it.)
//
// This leads to unprecise type labels in the UI.  A possible solution would be
// to get the type annotation from XQuery, but this will probably suffer from
// the same flaw, only the other way arround (so the JavaScript 'foobar' would
// be an "xs:string".)
//
// So probably, the only way is to evaluate and extract types in XQuery for
// XQuery code and in JavaScript for JavaScript code...

// an item is either a simple JS type, or a node, or an xs:* type, or a cts:* type,
// or an object with a constructor
const item = (i) => {
    const desc = { value: i };
    if ( i === null ) {
        desc.type = 'null';
    }
    else if ( typeof i === 'object' ) {
        const c = i.constructor.name;
        const n = nodes[c];
        if ( n ) {
            desc.type = n;
            desc.kind = 'node';
        }
        else if ( c.startsWith('xs.') ) {
            desc.type = 'xs:' + c.slice(3);
            desc.kind = 'atomic';
        }
        else if ( c.startsWith('cts.') ) {
            desc.type = 'cts:' + c.slice(4);
            desc.kind = 'cts:query';
        }
        else if ( c === 'sem.iri' ) {
            desc.type = 'sem:iri';
            desc.kind = 'atomic';
        }
        else {
            // TODO: Is there really no way to distinguish a map:map from a JSON object?
            desc.type = 'object';
            desc.kind = 'object';
            desc.constructor = c;
        }
    }
    else {
        desc.type = typeof i;
    }
    resp.result.push(desc);
};

if ( res instanceof Sequence ) {
    for ( const i of res ) {
        item(i);
    }
}
else {
    item(res);
}

resp.time.total = xdmp.elapsedTime();
resp;
