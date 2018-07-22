"use strict";

module.exports = (() => {
    const xqy = require('job-lib.xqy');

    function OLD_XXX_create(name, desc, code, lang, target, dry) {
	if ( lang !== 'sjs' && lang !== 'xqy' ) {
	    throw new Error(`Unknown language: ${lang}`);
	}
	const targets = xqy.resolveTarget(target);

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
		name     : name,
		desc     : desc,
		lang     : lang,
		target   : target,
		database : targets.database,
		lang     : lang,
		created  : new Date().toISOString()
	    };
	    if ( targets.modules !== undefined ) {
		res.modules = targets.modules;
	    }
	    return res;
	}

	function sjsJob(params, tasks, code) {
	    const job = { job: {
		id:       params.id,
		uri :     params.uri,
		coll:     params.coll,
		created:  params.created,
		name:     params.name,
		desc:     params.desc,
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
	    return xqy.makeJob(params, tasks, code);
	}

	function xqyTask(params, chunk) {
	    return xqy.makeTask(params, chunk);
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
		// TODO: Status should be "created", then "ready" when the tasks are
		// created, then "started" right after running, then "success" or
		// "failure" after stopping.  For now, we do both creation and
		// initialization at once, here.
		collections: [ '/kind/' + kind, '/status/ready', coll ]
	    });
	}

	const params = getParams();
	const result = {
	    dry:   dry,
	    job:   params,
	    tasks: []
	};

	// the chunks
	const options = {
	    update:   'false',
	    database: targets.database,
	    modules:  targets.modules
	};
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

	return result;
    }

    function create(name, desc, lang, target) {
	if ( lang !== 'sjs' && lang !== 'xqy' ) {
	    throw new Error(`Unknown language: ${lang}`);
	}
	// TODO: Resolve the name of database and modules for clarity.
	function getParams() {
	    const targets = xqy.resolveTarget(target);
	    const uuid    = sem.uuidString();
	    const id      = uuid.slice(0, 13) + uuid.slice(14, 18);
	    const coll    = '/jobs/' + id;
	    const uri     = coll + '/job.' + (lang === 'sjs' ? 'json' : 'xml');
	    const res     = {
		id       : id,
		coll     : coll,
		uri      : uri,
		name     : name,
		desc     : desc,
		lang     : lang,
		target   : target,
		database : targets.database,
		lang     : lang,
		created  : new Date().toISOString()
	    };
	    if ( targets.modules !== undefined ) {
		res.modules = targets.modules;
	    }
	    return res;
	}
	// the job
	const params = getParams();
	const job    = lang === 'sjs'
	    ? { job: params }
	    : xqy.makeJob(params);
	// TODO: Status should be "created", then "ready" when the tasks are
	// created, then "started" right after running, then "success" or
	// "failure" after stopping.  For now, we do both creation and
	// initialization at once, here.
	xdmp.documentInsert(params.uri, job, {
	    collections: [ '/kind/job', '/status/ready', params.coll ]
	});
	return params;
    }

    return {
	create: create
    };
})();
