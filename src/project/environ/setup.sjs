"use strict";

const cmd  = require('../mlproj/commands');
// WTF is happening to path resolution?!?
const lib  = require('../../project/environ/environ-lib');
const view = require('../../project/environ/setup.xqy');
const t    = require('../../lib/tools.xqy');

const project = t.mandatoryField('project');
const environ = t.mandatoryField('environ');

lib.withProject(
    project,
    environ,
    (proj, platform, display) => {
	const command = new cmd.SetupCommand({}, {}, platform, display, proj);
	const actions = command.prepare();
	// draw the action, which will be orchastrated by the client
	return view.page(environ, project, actions.todo.map(a => a.toValues()));
    },
    (err) => {
	// draw the page in case of error
	return view.error(environ, project, err);
    });
