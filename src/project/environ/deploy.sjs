"use strict";

const cmd  = require('../mlproj/commands');
// WTF is happening to path resolution?!?
const lib  = require('../../project/environ/environ-lib');
const view = require('../../project/environ/load.xqy');
const t    = require('../../lib/tools.xqy');

const project = fn.head(t.mandatoryField('project'));
const environ = fn.head(t.mandatoryField('environ'));
// TODO: There will be a source-srcset when source sets are supported.
const source  = fn.head(t.mandatoryField('source-path'));
const target  = fn.head(t.mandatoryField('target'));

lib.loadDeploy(
    project,
    environ,
    source,
    target,
    cmd.DeployCommand,
    (cmdArgs, actions) => view.page(environ, project, 'deploy', cmdArgs, actions),
    err => view.error(environ, project, err));
