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
 * TODO: Handle errors from evaluating the query.
 * TODO: Support update queries.
 * TODO: Add the document URI for nodes?  To allow browsing.
 * TODO: Return the result of a SPARQL query in a specific (tabular) way?
 */

const a   = require('/lib/admin.xqy');
const t   = require('/lib/tools.xqy');
const xqy = require('/api/tool/lib.xqy');

main(xdmp.getRequestBody().toObject());

function main(req)
{
    if ( req.lang !== 'javascript' && req.lang !== 'xquery' ) {
        t.error('wrong-param', `The param lang is neither javascript nor xquery: ${req.lang}`);
    }

    // get the actual target
    const db = t.databaseExists(req.target);
    const as = t.appserverExists(req.target);

    if ( db && as ) {
        t.error('wrong-param', `Target matches both database and appserver: ${req.target}`);
    }
    else if ( ! db && ! as ) {
        t.error('wrong-param', `Target does not exist: ${req.target}`);
    }

    // the options for eval()
    const options = {};
    if ( db ) {
        options.database = db;
    }
    else {
        options.database = xdmp.serverDatabase(as);
        options.modules  = xdmp.serverModulesDatabase(as);
        options.root     = xdmp.serverRoot(as);
    }

    // the query variables/parameters
    const vars = {};
    for ( const p of req.params ) {
        let v = p.value;
        if ( p.type ) {
            const l = p.label || p.name;
            if ( ! p.type.startsWith('xs:') ) {
                t.error('wrong-param', `Not an xs: type on param ${l}: ${p.type}`);
            }
            const ctor = xs[p.type.slice(3)];
            if ( ! ctor ) {
                t.error('wrong-param', `No such type on param ${l}: ${p.type}`);
            }
            try {
                switch ( p.occurrence ) {
                case undefined:
                    v = ctor(p.value);
                    break;
                case '?':
                    v = p.value === undefined || p.value === ''
                        ? null
                        : ctor(p.value);
                    break;
                case '*':
                case '+':
                    t.error('wrong-param', `Occurrence '*' and '+' not supported on param ${l}`);
                default:
                    t.error('wrong-param', `Unknwon occurrence on param ${l}: ${p.occurrence}`);
                }
            }
            catch ( err ) {
                t.error('wrong-param', `Invalid value for param ${l} for type ${p.type}: ${err}`);
            }
        }
        vars[p.name] = v;
    }

    // prepare the result
    const resp = {
        input: {
            body: req,
            database: db,
            server: as,
            dbname: xdmp.databaseName(options.database),
            options: options
        }
    };

    // do it
    const start = xs.dateTime(new Date());
    resp.result = req.lang === 'javascript'
        ? evalJavaScript(req.code, vars, options)
        : xqy.evalXquery(req.code, vars, options).toArray();
    const end = xs.dateTime(new Date());

    // add timing info
    resp.time = {
        eval:  end.subtract(start),
        total: xdmp.elapsedTime()
    };

    return resp;
}

function evalJavaScript(code, vars, options)
{
    const res    = xdmp.eval(code, vars, options)
    const result = [];

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

    // an item is either a simple JS type, or a node, or an xs:* type, or a cts:* type,
    // or an object with a constructor
    // TODO: Use xdmp.type() as in XQuery?
    const item = (i) => {
        const desc = { value: i };
        if ( i === null ) {
            desc.type = 'null';
        }
        else if ( typeof i === 'object' ) {
            const c = i.constructor.name;
            if ( i instanceof Node ) {
                desc.type = xdmp.nodeKind(i);
                desc.kind = 'node';
            }
            else if ( c.startsWith('xs.') ) {
                desc.type = 'xs:' + c.slice(3);
                desc.kind = 'atomic';
            }
            else if ( c.startsWith('cts.') ) {
                desc.type = 'cts:' + c.slice(4);
                desc.kind = 'query';
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
        result.push(desc);
    };

    // if exactly one single array, unbox it
    if ( fn.exists(res) && fn.empty(fn.tail(res)) && Array.isArray(fn.head(res)) ) {
        for ( const i of fn.head(res) ) {
            item(i);
        }
    }
    else {
        for ( const i of res ) {
            item(i);
        }
    }

    return result;
}
