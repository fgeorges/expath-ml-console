"use strict";

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

// the project
const p = platform.project(environ, null, dir, params, force);
// execute the command
const command = new cmd.ShowCommand({}, {}, platform, display, p);
command.execute();

view.page(environ, display.content);
