"use strict";

// TODO: Factorize this script with load.sjs, show.sjs and action.sjs.

const cmd  = require('../mlproj/commands');
const ml   = require('../mlproj/ml');
// WTF is happening to path resolution?!?
const proj = require('../../project/proj-lib.xqy');
const view = require('../../project/environ/setup.xqy');
const t    = require('../../lib/tools.xqy');

const project = t.mandatoryField('project');
const environ = t.mandatoryField('environ');
const dir     = proj.directory(proj.project(project));

// TODO: Values...
const dry      = true;
const verbose  = true;
const platform = new ml.Platform(dry, verbose);
const display  = new ml.Display();

// TODO: Values...
const params = {};
const force  = {};

try {
    // the project
    const p = platform.project(environ, null, dir, params, force);
    // execute the command
    const command = new cmd.SetupCommand({}, {}, platform, display, p);
    const actions = command.prepare();
    // draw the action, which will be orchastrated by the client
    view.page(environ, project, actions.todo.map(a => a.toValues()));
}
catch (err) {
    // draw the page in case of error
    if ( err.mlerr ) {
        view.error(environ, project, err);
    }
    else {
        view.error(environ, project, {
	    name    : err.name,
	    message : err.message,
	    stack   : err.stack
	});
    }
}
