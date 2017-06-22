"use strict";

// TODO: Factorize this script with action.sjs, setup.sjs and show.sjs.

const cmd  = require('../mlproj/commands');
const ml   = require('../mlproj/ml');
// WTF is happening to path resolution?!?
const proj = require('../../project/proj-lib.xqy');
const view = require('../../project/environ/load.xqy');
const t    = require('../../lib/tools.xqy');

const project = fn.head(t.mandatoryField('project'));
const environ = fn.head(t.mandatoryField('environ'));
// TODO: There will be a source-srcset when source sets are supported.
const source  = fn.head(t.mandatoryField('source-path'));
const target  = fn.head(t.mandatoryField('target'));
const dir     = proj.directory(proj.project(project));

try {
    // TODO: Values...
    const dry      = true;
    const verbose  = true;
    const platform = new ml.Platform(dry, verbose, dir);
    const display  = new ml.Display();

    // TODO: Values...
    const params = {};
    const force  = {};

    var cmdArgs = {};
    // source
    if ( platform.isDirectory(source) ) {
	cmdArgs.directory = source;
    }
    else {
	cmdArgs.document = source;
    }
    // target
    if ( target.startsWith('db:') ) {
	cmdArgs.database = target.slice('db:'.length);
    }
    else if ( target.startsWith('srv:') ) {
	cmdArgs.server = target.slice('srv:'.length);
    }
    else if ( target.startsWith('other:') ) {
	cmdArgs.forceDb = target.slice('other:'.length);
    }
    else {
	throw new Error('Internal error: target is neither db:*, srv:* or other:* - ' + target);
    }

    // the project
    const p = platform.project(environ, null, dir, params, force);
    // execute the command
    const command = new cmd.LoadCommand({}, cmdArgs, platform, display, p);
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
