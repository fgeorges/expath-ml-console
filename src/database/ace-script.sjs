"use strict";

const t    = require('/lib/tools.xqy');
const init = require('/init/lib-init.xqy');

const uri = init.aceBaseUri + t.mandatoryField('name') + '.js';

if ( fn.docAvailable(uri) ) {
    fn.doc(uri);
}
else {
    t.respondNotFound('No such document: ' + uri);
}
