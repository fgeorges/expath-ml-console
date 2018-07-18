"use strict";

// WTF is happening to path resolution?!?
const cmd  = require('../../project/mlproj/commands');
const lib  = require('../../project/environ/environ-lib');
const view = require('../../project/environ/load.xqy');
const t    = require('../../lib/tools.xqy');

const project = fn.head(t.mandatoryField('project'));
const environ = fn.head(t.mandatoryField('environ'));
const target  = fn.head(t.mandatoryField('target'));

var srcSet;
var srcPath;
if ( t.optionalField('source-srcset-check', null) ) {
    srcSet = fn.head(t.mandatoryField('source-srcset'));
}
else if ( t.optionalField('source-path-check', null) ) {
    srcPath = fn.head(t.mandatoryField('source-path'));
}

lib.loadDeploy(
    project,
    environ,
    srcSet,
    srcPath,
    target,
    'deploy',
    cmd.DeployCommand,
    (cmdArgs, actions) => view.page(environ, project, 'deploy', cmdArgs, actions),
    err => view.error(environ, project, err));
