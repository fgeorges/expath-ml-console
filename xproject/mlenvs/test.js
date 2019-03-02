// To be used in conjunction with another environment, for the connect info:
//
//     > mlproj -e dev/test load -b test
//
// Use the following query in QConsole to transform Turtle files to MarkLogic
// sem:triples documents:
//
//     'use strict';
//
//     declareUpdate();
//
//     const sem = require('/MarkLogic/semantics.xqy');
//
//     const res = [];
//     for ( const uri of cts.uris() ) {
//       const u = uri.toString();
//       if ( u.startsWith('/star-wars-dataset/') && u.endsWith('.ttl') ) {
//         const n = u.slice(0, -3) + 'xml';
//         const c = sem.rdfSerialize(sem.rdfParse(fn.doc(u), 'turtle'), 'triplexml');
//         xdmp.documentInsert(n, c);
//         res.push(n);
//       }
//     }
//     res;


module.exports = function() {
    return {
        mlproj: {
            format: '0.1',
            sources: [{
                name:   'data',
                dir:    'test/data',
                target: 'test'
            }],
            databases: [{
	        id:   'test',
	        name: '@{code}-test-content'
            }]
        }
    };
};
