"use strict";

const cmd  = require('../mlproj/commands');
// WTF is happening to path resolution?!?
const lib  = require('../../project/environ/environ-lib');
const view = require('../../project/environ/show.xqy');
const t    = require('../../lib/tools.xqy');

const project = fn.head(t.mandatoryField('project'));
const environ = fn.head(t.mandatoryField('environ'));

lib.withProject(
    project,
    environ,
    (ctxt, env) => {
	const command = new cmd.ShowCommand({}, {}, ctxt, env);
	const actions = command.prepare();
	actions.execute();
	if ( actions.error ) {
            return view.error(environ, project, actions.error);
	}
	else {
	    return view.page(environ, project, ctxt.display.content);
	}
    },
    (err) => {
        return view.error(environ, project, err);
    });
