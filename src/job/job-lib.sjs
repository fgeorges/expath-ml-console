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

    const sampleInitXqy = `(: This is a job creation query.
 : It must select the chunks each task will be executed with.
 : Replace this code with your own query.
 :)

xquery version "3.1";

declare namespace cts = "http://marklogic.com/cts";

declare variable $size := 10;

declare function local:uris($uris as xs:string*) as element(uris)* {
    if ( fn:empty($uris) ) then (
    )
    else (
        <uris> {
            $uris[position() le $size] ! <uri>{ . }</uri>
        }
        </uris>,
        local:uris($uris[position() gt $size])
    )
};

local:uris(cts:uris())
`;

    const sampleInitSjs = `// This is a job creation script.
// It must select the chunks each task will be executed with.
// Replace this code with your own script.

"use strict";

const size    = 10;
const chuncks = [];

let current = [];
let i = 0;
for ( const uri of cts:uris() ) {
    current.push(uri);
    ++i;
    if ( i === size ) {
        chuncks.push(current);
        current = [];
    }
}

chuncks;
`;

    const sampleExecXqy = `(: This is a task execution query.
 : It receives the task to execute as the global param "$task".
 : Replace this code with your own query.
 :)

xquery version "3.1";

declare namespace c    = "http://expath.org/ns/ml/console";
declare namespace xdmp = "http://marklogic.com/xdmp";

declare variable $task as element(c:task) external;

xdmp:log("TODO: Run job: " || $task/c:id)
`;

    const sampleExecSjs = `// This is a task execution script.
// It receives the task to execute as the variable "task".
// Replace this code with your own query.

"use strict";

cosnole.log('TODO: Run job: ' + task.id)
`;

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
	    const uri     = coll + '/job.'  + (lang === 'sjs' ? 'json' : 'xml');
	    const init    = coll + '/init.' + (lang === 'sjs' ? 'sjs'  : 'xqy');
	    const exec    = coll + '/exec.' + (lang === 'sjs' ? 'sjs'  : 'xqy');
	    const res     = {
		id       : id,
		uri      : uri,
		coll     : coll,
		name     : name,
		desc     : desc,
		lang     : lang,
		target   : target,
		database : targets.database,
		created  : new Date().toISOString(),
		init     : init,
		exec     : exec
	    };
	    if ( targets.modules !== undefined ) {
		res.modules = targets.modules;
	    }
	    return res;
	}

	// create and save the job
	const params = getParams();
	const job    = lang === 'sjs'
	    ? { job: params }
	    : xqy.makeJob(params);
	xdmp.documentInsert(
	    params.uri,
	    job,
	    { collections: [ '/kind/job', '/status/created', params.coll ]});

	// create and save the creation module
	const ibuilder = new NodeBuilder();
	ibuilder.startDocument();
	ibuilder.addText(lang === 'sjs' ? sampleInitSjs : sampleInitXqy);
	ibuilder.endDocument();
	xdmp.documentInsert(
	    params.init,
	    ibuilder.toNode(),
	    { collections: [ params.coll ]});

	// create and save the task execution module
	const ebuilder = new NodeBuilder();
	ebuilder.startDocument();
	ebuilder.addText(lang === 'sjs' ? sampleExecSjs : sampleExecXqy);
	ebuilder.endDocument();
	xdmp.documentInsert(
	    params.exec,
	    ebuilder.toNode(),
	    { collections: [ params.coll ]});

	return params;
    }

    function init(id) {
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
		// TODO: Should rather come from the init code
		//label:   'Number of items in the chunk: ' + (Array.isArray(chunk) ? chunk.length : 1),
		created: new Date().toISOString()
	    };
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

	function xqyTask(params, chunk) {
	    return xqy.makeTask(params, chunk);
	}

	// TODO: Retrieve all needed info from the job document (lang, init
	// module, content and modules databases, etc.)
	// Reuse the code from OLD_XXX_create() above.
	const job     = xqy.job(id);
	const lang    = xqy.lang(job);
	const coll    = xqy.collection(job);
	// we cannot invoke the init module, as it is stored in the EMLC content
	// database, so it must be invoked from that database as the modules
	// database, but we want to be able to evaluate it with the specified
	// modules database (if any) to resolve the imports (so we read the
	// content of the module, to evaluate it)
	const code    = cts.doc(xqy.initModule(job));
	const content = xqy.database(job);
	const modules = xqy.modules(job);

	// evaluating the init code to get the chunks
	const options = {
	    update:   'false',
	    database: content
	};
	if ( modules === 0 || modules ) {
	    options.modules = modules;
	}
	const chunks  = lang === 'sjs'
	    // must be exactly one array
	    ? fn.exactlyOne(xdmp.eval(code, null, options))
	    : xdmp.xqueryEval(code, null, options);

	// the tasks
	const result = [];
	let i = 0;
	for ( const chunk of chunks ) {
	    ++ i;
	    const params = taskParams(i, id, coll, chunk);
	    result.push(params);
	    const task   = lang === 'sjs'
		? sjsTask(params, chunk)
		: xqyTask(params, chunk);
	    xdmp.documentInsert(
		params.uri,
		task,
		{ collections: [ '/kind/task', '/status/created', coll ]});
	}

	// TODO: Add the list of tasks to the job doc... (id + uri, at least)

	// the job is ready now
	xqy.setStatus(job, xqy['status.ready']);

	return result;
    }

    return {
	create: create,
	init:   init
    };
})();
