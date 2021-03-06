"use strict";

module.exports = (() => {
    const xqy = require('job-lib.xqy');

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
for ( const uri of cts.uris() ) {
    current.push(uri);
    ++i;
    if ( ! (i % size) ) {
        chuncks.push(current);
        current = [];
    }
}
if ( current.length ) {
    chuncks.push(current);
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

console.log('TODO: Run job: ' + task.id)
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
		lang     : lang,
		target   : target,
		database : targets.database,
		created  : new Date().toISOString(),
		init     : init,
		exec     : exec
	    };
	    if ( desc ) {
		res.desc = desc;
	    }
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
