"use strict";

const cmd  = require('../mlproj/commands');
const ml   = require('../mlproj/ml');
const proj = require('../../project/proj-lib.xqy');
const t    = require('../../lib/tools.xqy');

const project = t.mandatoryField('project');
const environ = t.mandatoryField('environ');
const dir     = proj.directory(proj.project(project));


// TODO: Values...
const dry      = true;
const verbose  = true;
const platform = new ml.MarkLogic(dry, verbose);

// TODO: Values...
const params = null;
const force  = null;
const args   = null;

// the project
platform.project(environ, null, dir, params, force, project => {
    // execute the command
    project.execute(args, core.ShowCommand);
});
