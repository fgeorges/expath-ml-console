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
    (proj, platform, display) => {
	const command = new cmd.ShowCommand({}, {}, platform, display, proj);
	const actions = command.prepare();
	command.execute(actions);
	return view.page(environ, project, display.content);
    },
    (err) => {
        return view.error(environ, project, err);
    });
