"use strict";

const t = require('../../lib/tools.xqy');

const code     = fn.head(t.mandatoryField('code'));
const lang     = fn.head(t.mandatoryField('lang'));
const database = fn.head(t.optionalField('database', null));
const modules  = fn.head(t.optionalField('modules', null));
const dry      = fn.head(t.optionalField('dry', 'false'));

if ( lang === 'xqy' ) {
    throw new Error(`XQuery not supported yet`);
}
else if ( lang === 'sjs' ) {
    // nothing, just continue for now
}
else {
    throw new Error(`Unknown language: ${lang}`);
}

const options = {
    update: false
};

if ( database ) {
    options.database = xdmp.database(database);
}
if ( modules ) {
    options.modules = xdmp.database(modules);
}

const uuid = sem.uuidString();
const jid  = uuid.slice(0, 13) + uuid.slice(14, 18);
const coll = `/jobs/${jid}`;
const juri = `${coll}/job.json`;
const job  = { job: {
    id:       jid,
    uri :     juri,
    coll:     coll,
    created:  new Date().toISOString(),
    creation: code,
    tasks:    []
}};
// must be exactly one array
const chunks = fn.exactlyOne(xdmp.eval(code, options));
const tasks  = [];

chunks.forEach((chunk, i) => {
    const str    = (i + 1).toString();
    const padded = str.length >= 6
	? str
	: new Array(6 - str.length + 1).join('0') + str;
    const num    = padded.slice(0, 3) + '-' + padded.slice(3);
    const tid    = `${jid}/${num}`;
    const turi   = `${coll}/task-${num}.json`;
    job.job.tasks.push({
	id:  tid,
	uri: turi
    });
    tasks.push({ task: {
	id:      tid,
	uri:     turi,
	order:   i + 1,
	num:     num,
	label:   'Number of items in the chunk: ' + (Array.isArray(chunk) ? chunk.length : 1),
	created: new Date().toISOString(),
	chunk:   chunk
    }});
});

const res = {};

if ( dry === 'true' ) {
    res.dry   = xdmp.describe(dry);
    res.job   = job.job;
    res.tasks = tasks.map(t => t.task);
    res.time  = xdmp.elapsedTime();
}
else {
    throw new Error(`FIXME: TODO: Non-dry mode not supported yet...`);
}

res;
