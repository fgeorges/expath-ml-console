"use strict";

/*~
 * Return the triples with subject `subject`, on database `db` (using `rules`).
 *
 * The value of `subject` is interpreted with regard to the parameter `subject-type` (the
 * default is `iri`).  The possible types are:
 *
 * - iri - a full IRI
 * - curie - a CURIE, given the triple prefixes configured on the database
 * - rdf:langString - an RDF langString, with the lang in `subject-lang`
 * - xs:* - a value with the given XML Schema type (xs:string, xs:dateTime, etc.)
 *
 * If `subject-lang` is passed, then the default value for `subject-type` is
 * `rdf:langString`, so it is not mandatory to set it as well.
 *
 * Similar to `subject`, `subject-type` and `subject-lang`, the service can be invoked
 * with the same parameters, only with `subject*` replaced by `predicate*` or `object*`,
 * to set resp. the predicate or the object of the triples to search for.  Any combination
 * of `subject*`, `predicate*` and `object*` is allowed (given than each "set" of params
 * is consistent, and at least one if provided).
 *
 * The type `xs:QName` is not supported.
 *
 * The result is an object with a property `triples`, an array of triples with the
 * following format:
 *
 *   { triples: [
 *       {subject: ..., object: ..., predicate: ...},
 *       {subject: ..., object: ..., predicate: ...},
 *       ...
 *   ]}
 *
 * Each atom is an object with the following properties:
 *
 *   {type, iri, abbrev, curie?, blank?, labels?, classes?}  ||  {type, value, numeric?, lang?}
 *
 * In the case of a resource (an IRI):
 *
 * - type: `iri`
 * - iri: the IRI
 * - `abbrev`: the CURIE, or `...#Foo`, or `.../Bar`, or full IRI if nothing shorter
 * - `curie`: the CURIE if a matching prefix is configured for the database `db`
 * - `blank`: `true` if this is a blank node, falsy if not
 * - `labels`: an array of strings, with all the `rdfs:label`
 * - `classes`: an array of objects, with all the `rdf:type` (each: {iri, abbrev, curie?})
 *
 * In the case of a simple value (not an IRI):
 *
 * - `type`: `rdf:langString`, or an `xs:*` type
 * - `value`: the value itself (as a string, or as a number for numeric types)
 * - `numeric`: `true` if a numeric type, falsy if not
 * - `lang`: the language for an `rdf:langString`
 *
 * TODO: Add windowing.
 */

(() => {
    const sjs     = require('/lib/sjs');
    const tools   = require('/lib/tools.xqy');
    const triples = require('/lib/triples.xqy');
    const dbc     = require('/database/db-config-lib.xqy');

    // globals (service params and constants)
    const db       = sjs.mandatoryField('db');
    const rules    = sjs.optionalField('rules', null);
    const prefixes = dbc.configTriplePrefixes(db);

    function abbreviate(atom) {
        atom.abbrev = triples.abbreviate(atom.iri, atom.curie);
    }

    function resolve(value, type, lang) {
        if ( ! value ) {
            if ( type || lang ) {
                throw new Error(`Type and lang are only allowed with a value: ${type}/${lang}`);
            }
            return null;
        }
        const typed = convert(value, type, lang);
        const rsrc  = {};
        if ( sem.isIRI(typed) ) {
            const curie = triples.curie(typed, prefixes);
            rsrc.type = 'iri';
            rsrc.iri  = typed;
            if ( curie ) {
                rsrc.curie = curie;
            }
            abbreviate(rsrc);
        }
        else {
            rsrc.type  = type;
            rsrc.value = typed;
        }
        return rsrc;
    }

    function convert(value, type, lang) {
        if ( ! type ) {
            type = lang ? 'rdf:langString' : 'iri';
        }
        else if ( lang && type !== 'rdf:langString' ) {
            throw new Error(`The lang parameter is only allowed with rdf:langString: ${type}`);
        }
        switch ( type ) {
        case 'iri':
            return sem.iri(value);
        case 'curie': {
            const iri = triples.expand(value, dbc.configTriplePrefixes(db));
            if ( ! iri ) {
                throw new Error(`CURIE ${value} cannot be resolved on ${db}`);
            }
            return sem.iri(iri);
        }
        case 'rdf:langString':
            return rdf.langString(value, lang);
        case 'xs:ENTITIES':
            return xs.ENTITIES(value);
        case 'xs:ENTITY':
            return xs.ENTITY(value);
        case 'xs:ID':
            return xs.ID(value);
        case 'xs:IDREF':
            return xs.IDREF(value);
        case 'xs:IDREFS':
            return xs.IDREFS(value);
        case 'xs:NCName':
            return xs.NCName(value);
        case 'xs:NMTOKEN':
            return xs.NMTOKEN(value);
        case 'xs:NMTOKENS':
            return xs.NMTOKENS(value);
        case 'xs:NOTATION':
            return xs.NOTATION(value);
        case 'xs:Name':
            return xs.Name(value);
        case 'xs:QName':
            // not supported, as they rely on the namespaced declared here
            // if support is ever needed, could be done using Clark notation
            throw new Error(`QNames not supported: ${value}`);
        case 'xs:anyAtomicType':
            return xs.anyAtomicType(value);
        case 'xs:anySimpleType':
            return xs.anySimpleType(value);
        case 'xs:anyURI':
            return xs.anyURI(value);
        case 'xs:base64Binary':
            return xs.base64Binary(value);
        case 'xs:boolean':
            return xs.boolean(value);
        case 'xs:byte':
            return xs.byte(value);
        case 'xs:date':
            return xs.date(value);
        case 'xs:dateTime':
            return xs.dateTime(value);
        case 'xs:dateTimeStamp':
            return xs.dateTimeStamp(value);
        case 'xs:dayTimeDuration':
            return xs.dayTimeDuration(value);
        case 'xs:decimal':
            return xs.decimal(value);
        case 'xs:double':
            return xs.double(value);
        case 'xs:duration':
            return xs.duration(value);
        case 'xs:float':
            return xs.float(value);
        case 'xs:gDay':
            return xs.gDay(value);
        case 'xs:gMonth':
            return xs.gMonth(value);
        case 'xs:gMonthDay':
            return xs.gMonthDay(value);
        case 'xs:gYear':
            return xs.gYear(value);
        case 'xs:gYearMonth':
            return xs.gYearMonth(value);
        case 'xs:hexBinary':
            return xs.hexBinary(value);
        case 'xs:int':
            return xs.int(value);
        case 'xs:integer':
            return xs.integer(value);
        case 'xs:language':
            return xs.language(value);
        case 'xs:long':
            return xs.long(value);
        case 'xs:negativeInteger':
            return xs.negativeInteger(value);
        case 'xs:nonNegativeInteger':
            return xs.nonNegativeInteger(value);
        case 'xs:nonPositiveInteger':
            return xs.nonPositiveInteger(value);
        case 'xs:normalizedString':
            return xs.normalizedString(value);
        case 'xs:positiveInteger':
            return xs.positiveInteger(value);
        case 'xs:short':
            return xs.short(value);
        case 'xs:string':
            return xs.string(value);
        case 'xs:time':
            return xs.time(value);
        case 'xs:token':
            return xs.token(value);
        case 'xs:unsignedByte':
            return xs.unsignedByte(value);
        case 'xs:unsignedInt':
            return xs.unsignedInt(value);
        case 'xs:unsignedLong':
            return xs.unsignedLong(value);
        case 'xs:unsignedShort':
            return xs.unsignedShort(value);
        case 'xs:yearMonthDuration':
            return xs.yearMonthDuration(value);
        default:
            throw new Error(`Unknown type: ${type}, for value: ${value}`);
        }
    }

    function tojson(value) {
        const res = {};
        if ( sem.isIRI(value) || sem.isBlank(value) ) {
            const curie = triples.curie(value, prefixes);
            res.type = 'iri';
            res.iri  = value;
            if ( sem.isBlank(value) ) {
                res.blank = true;
            }
            if ( curie ) {
                res.curie = curie;
            }
            abbreviate(res);
        }
        else {
            const type = sem.datatype(value).toString();
            res.value = value;
            res.type  = type;
            if ( type.startsWith(triples.rdfUri) ) {
                res['type-curie'] = 'rdf:' + type.slice(triples.rdfUri.length);
            }
            else if ( type.startsWith(triples.xsUri) ) {
                res['type-curie'] = 'xs:' + type.slice(triples.xsUri.length);
            }
            if ( sem.isNumeric(value) ) {
                res.numeric = true;
            }
            const lang = sem.lang(value);
            if ( lang ) {
                res.lang = lang;
            }
        }
        return res;
    };

    const subj = resolve(
        sjs.optionalField('subject'),
        sjs.optionalField('subject-type', null),
        sjs.optionalField('subject-lang', null));

    const pred = resolve(
        sjs.optionalField('predicate'),
        sjs.optionalField('predicate-type', null),
        sjs.optionalField('predicate-lang', null));

    const obj = resolve(
        sjs.optionalField('object'),
        sjs.optionalField('object-type', null),
        sjs.optionalField('object-lang', null));

    if ( ! subj && ! pred && ! obj ) {
        throw new Error(`At least one of subject, predicate or object is mandatory.`);
    }

    // TODO: For temporal documents, should be sem:store((), cts:collection-query('latest'))
    // Or not, if the database only got triples for `latest` already, e.g. if they are
    // projected through TDE, and they are restricted to `latest`.
    const store = rules && sem.rulesetStore(rules.split(','), sem.store());

    // the "main" query
    // TODO: Support windowing, in case one single resources has thousands of triples.
    const query = `
        SELECT * WHERE {
          ?subj ?pred ?obj .
        }`;
    const params = {};
    if ( subj ) { params.subj = subj.iri || subj.value; }
    if ( pred ) { params.pred = pred.iri || pred.value; }
    if ( obj  ) { params.obj  = obj.iri  || obj.value;  }
    const matches = sjs.query(db, () => triples.sparql(query, params, store, [], []));

    // resolve the labels and classes
    const iris = {};
    for ( const m of matches ) {
        const s = (m.subj && sem.isIRI(m.subj) && m.subj) || (subj && subj.iri);
        const p = (m.pred && sem.isIRI(m.pred) && m.pred) || (pred && pred.iri);
        const o = (m.obj  && sem.isIRI(m.obj)  && m.obj)  || (obj  && obj.iri);
        if ( s ) { iris[s] = s; }
        if ( p ) { iris[p] = p; }
        if ( o ) { iris[o] = o; }
    }
    const labels  = {};
    const classes = {};
    const keys    = Object.keys(iris);
    if ( keys.length ) {
        const q2 = `
            PREFIX rdf:  <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
            PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
            SELECT ?iri ?label ?clazz WHERE {
              { ?iri rdfs:label ?label . }
              UNION
              { ?iri rdf:type ?clazz . }
              FILTER (?iri = ?iris)
            }`;
        const p2 = {iris: keys.map(k => iris[k])};
        const m2 = sjs.query(db, () => triples.sparql(q2, p2, store, [], []));
        for ( const m of m2 ) {
            if ( fn.head(m.label) ) {
                let slot = labels[m.iri];
                if ( ! slot ) {
                    slot = labels[m.iri] = [];
                }
                slot.push(m.label);
            }
            if ( fn.head(m.clazz) ) {
                let slot = classes[m.iri];
                if ( ! slot ) {
                    slot = classes[m.iri] = [];
                }
                const cl = {iri: m.clazz};
                const cu = triples.curie(m.clazz, prefixes);
                if ( cu ) { cl.curie = cu };
                abbreviate(cl);
                slot.push(cl);
            }
        }
    }

    const result = { triples: [] };
    for ( const m of matches ) {
        const res = {};
        res.subject   = subj || tojson(m.subj);
        res.predicate = pred || tojson(m.pred);
        res.object    = obj  || tojson(m.obj);
        const enrich = (slot) => {
            if ( slot.iri ) {
                const l = labels[slot.iri];
                if ( l ) {
                    slot.labels = l;
                }
                const c = classes[slot.iri];
                if ( c ) {
                    slot.classes = c;
                }
            }
        };
        enrich(res.subject);
        enrich(res.predicate);
        enrich(res.object);
        result.triples.push(res);
    }

    return result;
})();
