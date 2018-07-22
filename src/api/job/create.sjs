"use strict";

declareUpdate();

const t   = require('../../lib/tools.xqy');
const job = require('../../job/job-lib.sjs');

const name   = fn.head(t.mandatoryField('name'));
const desc   = fn.head(t.mandatoryField('desc'));
const lang   = fn.head(t.mandatoryField('lang'));
const target = fn.head(t.mandatoryField('target'));

/* TODO: Code and dry to disapear (because used in the "init" phase.)
const code   = fn.head(t.mandatoryField('code'));
const dry    = getDry(fn.head(t.optionalField('dry', 'false')));
function getDry(d) {
    if ( d === 'true' ) {
	return true;
    }
    else if ( d === 'false' ) {
	return false;
    }
    else {
	throw new Error(`The param dry must be either true or false: ${d}`);
    }
}
*/

const result = job.create(name, desc, code, lang, target, dry);
result.time = xdmp.elapsedTime();
result;
