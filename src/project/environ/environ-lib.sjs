"use strict";

(function() {

    const ml   = require('../mlproj/ml');
    const proj = require('../../project/proj-lib.xqy');

    function withProject(id, environ, success, error) {
	try {
	    const dir = proj.directory(proj.project(id));

	    // TODO: Values...
	    const dry      = false;
	    const verbose  = true;
	    const platform = new ml.Platform(dry, verbose, dir);
	    const display  = new ml.Display();

	    // TODO: Values...
	    const params = {};
	    const force  = {};

	    // the project
	    const p = platform.project(environ, null, dir, params, force);

	    return success(p, platform, display);
	}
	catch (err) {
	    if ( err.mlerr ) {
		return error(err);
	    }
	    else {
		return error({
		    name    : err.name,
		    message : err.message,
		    stack   : err.stack
		});
	    }
	}
    }

    function loadDeploy(project, environ, source, target, cmd, view, error) {
	const addSource = (pf, args) => {
	    const path = pf.resolve(source);
	    if ( pf.isDirectory(path) ) {
		args.directory = source;
	    }
	    else {
		args.document = source;
	    }
	};

	const addTarget = (pf, args) => {
	    if ( target.startsWith('db:') ) {
		args.database = target.slice('db:'.length);
	    }
	    else if ( target.startsWith('srv:') ) {
		args.server = target.slice('srv:'.length);
	    }
	    else if ( target.startsWith('other:') ) {
		args.forceDb = target.slice('other:'.length);
	    }
	    else {
		throw new Error('Internal error: target is neither db:*, srv:* or other:* - ' + target);
	    }
	};

	return withProject(
	    project,
	    environ,
	    (proj, platform, display) => {
		// the command args
		var cmdArgs = {};
		addSource(platform, cmdArgs);
		addTarget(platform, cmdArgs);
		// prepare the command
		const command = new cmd({}, cmdArgs, platform, display, proj);
		const actions = command.prepare();
		// draw the actions, which will be orchestrated by the client
		return view(cmdArgs, actions.todo.map(a => a.toValues()));
	    },
	    error);
    }

    module.exports = {
        withProject : withProject,
	loadDeploy  : loadDeploy
    };
}
)();
