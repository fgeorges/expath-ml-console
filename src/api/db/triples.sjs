"use strict";

/*~
 * Return the triples with subject "subject", on database "db" (using "rules").
 *
 * The result is an object with a property "triples", an array of triples with the
 * following format:
 *
 *   { triples: [
 *       {predicate: ..., object: ..., predicate: ...},
 *       {predicate: ..., object: ..., predicate: ...},
 *       ...
 *   ]}
 *
 * Each value is an object with the following properties:
 *
 *   {iri, curie?}  ||  {type, type-curie?, value, lang?}  ||  {blank nodes...?}
 *
 * Either it is an IRI, and so it might have a CURIE as well if such a prefix is configured
 * on "db".  Or it is a simple value and it has also its type (a full IRI), the type CURIE
 * if it is an rdf:* or xs:* type, and a lang if it is an rdf:langString.
 *
 * TODO: Support blank nodes.
 *
 * TODO: Add windowing.
 *
 * TODO: Should be possible to pass subject as a CURIE also (not only an IRI), and support
 * subjects with a datatype (e.g. dateTimes, as in the Metrics database).
 */

(() => {
    const sjs     = require('/lib/sjs');
    const tools   = require('/lib/tools.xqy');
    const triples = require('/lib/triples.xqy');
    const dbc     = require('/database/db-config-lib.xqy');

    const db    = fn.head(tools.mandatoryField('db'));
    const subj  = fn.head(tools.mandatoryField('subject'));
    const rules = fn.head(tools.optionalField('rules', null));

    // TODO: For temporal documents, should be sem:store((), cts:collection-query('latest'))
    // Or not, if the database only got triples for `latest` already, e.g. if they are
    // projected through TDE, and they are restricted to `latest`.
    const store = rules && sem.rulesetStore(rules.split(','), sem.store());

    // TODO: Support windowing, in case one single resources has thousands of triples.
    const query = `
        PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
        SELECT ?pred ?obj ?label WHERE {
          $subj ?pred ?obj .
          OPTIONAL {
            ?obj rdfs:label ?label .
          }
        }
        ORDER BY ?pred`;

    const matches = sjs.query(
        db,
        () => triples.sparql(query, {subj: sem.iri(subj)}, null, [], []));

    const prefixes = dbc.configTriplePrefixes(db);
    const result   = { triples: [] };
    const subject  = { iri: subj };
    const curie    = triples.curie(subj, prefixes);
    if ( curie ) {
        subject.curie = curie;
    }

    const tojson = (value) => {
        const res = {};
        if ( sem.isBlank(value) ) {
            // TODO: Support blank nodes!
            throw new Error('Blank nodes not supported yet.  FIXME: Implement me!');
        }
        else if ( sem.isIRI(value) ) {
            res.iri = value;
            const curie = triples.curie(value, prefixes);
            if ( curie ) {
                res.curie = curie;
            }
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

    for ( const m of matches ) {
        result.triples.push({
            subject:   subject,
            predicate: tojson(m.pred),
            object:    tojson(m.obj)
        });
    }

    return result;
})();
