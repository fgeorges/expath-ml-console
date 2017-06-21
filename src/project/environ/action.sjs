"use strict";

// TODO: Factorize this script with show.sjs and setup.sjs.

const core = require('../mlproj/core');
const ml   = require('../mlproj/ml');
// WTF is happening to path resolution?!?
const proj = require('../../project/proj-lib.xqy');
const t    = require('../../lib/tools.xqy');

const project = t.mandatoryField('project').toString();
const environ = t.mandatoryField('environ').toString();
const action  = t.mandatoryField('action').toString();
const dir     = proj.directory(proj.project(project));

// TODO: Values...
const dry      = false;
const verbose  = true;
const platform = new ml.Platform(dry, verbose);

// TODO: Values...
const params = {};
const force  = {};

try {
    // the project
    const p    = platform.project(environ, null, dir, params, force);
    // execute the action
    const ctor = core.actions[action];
    if ( ! ctor ) {
	throw new Error('Action class does not exist: ' + action);
    }
    const a    = new ctor();
    a.fromValues({
	msg  : t.mandatoryField('msg').toString(),
	api  : t.mandatoryField('api').toString(),
	url  : t.mandatoryField('url').toString(),
	verb : t.mandatoryField('verb').toString(),
	data : t.optionalField('data', '').toString(),
	json : t.optionalField('json', 'false').toString() === 'true'
    });
    a.execute(platform);
}
catch (err) {
    var res = {
	error : {
	    name    : err.name,
	    message : err.message,
	    stack   : err.stack
	}
    };
    t.respondInternalError(res);
}
