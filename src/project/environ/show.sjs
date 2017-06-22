"use strict";

// TODO: Factorize this script with load.sjs, setup.sjs and action.sjs.

const cmd  = require('../mlproj/commands');
const ml   = require('../mlproj/ml');
// WTF is happening to path resolution?!?
const proj = require('../../project/proj-lib.xqy');
const view = require('../../project/environ/show.xqy');
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
    const command = new cmd.ShowCommand({}, {}, platform, display, p);
    const actions = command.prepare();
    command.execute(actions);
    // draw the page
    view.page(environ, project, display.content);
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
