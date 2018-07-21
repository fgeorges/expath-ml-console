"use strict";

declareUpdate();

const t   = require('../../lib/tools.xqy');
const xqy = require('create.xqy');

const code   = fn.head(t.mandatoryField('code'));
const lang   = fn.head(t.mandatoryField('lang'));
const target = fn.head(t.mandatoryField('target'));
const dry    = getDry(fn.head(t.optionalField('dry', 'false')));

const options = xqy.options(target);

if ( lang !== 'sjs' && lang !== 'xqy' ) {
    throw new Error(`Unknown language: ${lang}`);
}

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

// TODO: Resolve the name of database and modules for clarity.
function getParams() {
    const uuid = sem.uuidString();
    const id   = uuid.slice(0, 13) + uuid.slice(14, 18);
    const coll = '/jobs/' + id;
    const uri  = coll + '/job.' + (lang === 'sjs' ? 'json' : 'xml');
    const res  = {
	id       : id,
	coll     : coll,
	uri      : uri,
	lang     : lang,
	target   : target,
	database : options.database,
	lang     : lang,
	created  : new Date().toISOString()
    };
    if ( options.modules !== undefined ) {
	res.modules = options.modules;
    }
    return res;
}

function sjsJob(params, tasks, code) {
    const job = { job: {
	id:       params.id,
	uri :     params.uri,
	coll:     params.coll,
	created:  params.created,
	lang:     params.lang,
	target:   params.target,
	database: params.database,
	creation: code,
	tasks:    tasks
    }};
    if ( params.modules ) {
	job.job.modules = params.modules;
    }
    return job;
}

function sjsTask(params, chunk) {
    const task = { task: {
	id:      params.id,
	uri:     params.uri,
	order:   params.order,
	num:     params.num,
	label:   params.label,
	created: params.created,
	chunk:   chunk
    }};
    return task;
}

function xqyJob(params, tasks, code) {
    return xqy.job(params, tasks, code);
}

function xqyTask(params, chunk) {
    return xqy.task(params, chunk);
}

function taskParams(i, id, coll, chunk) {
    const str    = i.toString();
    const padded = str.length >= 6
        ? str
	: new Array(6 - str.length + 1).join('0') + str;
    const num    = padded.slice(0, 3) + '-' + padded.slice(3);
    const uri    = coll + '/task-' + num + '.' + (lang === 'sjs' ? 'json' : 'xml');
    return {
	id:      id + '/' + num,
	uri:     uri,
	order:   i,
	num:     num,
	label:   'Number of items in the chunk: ' + (Array.isArray(chunk) ? chunk.length : 1),
	created: new Date().toISOString()
    };
}

function save(doc, uri, kind, coll) {
    xdmp.documentInsert(uri, doc, {
	// TODO: Status should be "created", then "initialised" when the tasks
	// are created, then "started" right after running, then "success" or
	// "failure" after stopping.  For now, we do both creation and
	// initialization at once, here.
	collections: [ '/kind/' + kind, '/status/initialised', coll ]
    });
}

function main(params) {
    const result = {
	dry:   dry,
	job:   params,
	tasks: []
    };

    // the chunks
    const chunks  = lang === 'sjs'
        // must be exactly one array
        ? fn.exactlyOne(xdmp.eval(code, null, options))
        : xdmp.xqueryEval(code, null, options);

    // the tasks
    const tasks = [];
    let i = 0;
    for ( const chunk of chunks ) {
	++ i;
	const vars = taskParams(i, params.id, params.coll, chunk);
	tasks.push({
	    id:  vars.id,
	    uri: vars.uri
	});
	result.tasks.push(vars);
	const task = lang === 'sjs'
            ? sjsTask(vars, chunk)
            : xqyTask(vars, chunk);
	if ( ! dry ) {
            save(task, vars.uri, 'task', params.coll);
	}
    }

    // the job
    const job = lang === 'sjs'
	? sjsJob(params, tasks, code)
	: xqyJob(params, tasks, code);
    if ( ! dry ) {
        save(job, params.uri, 'job', params.coll);
    }

    result.time = xdmp.elapsedTime();
    return result;
}

main(getParams());
