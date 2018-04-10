"use strict";

declareUpdate();

const view = require('./create.xqy');
const proj = require('../proj-lib');
const ml   = require('../mlproj/ml');
const core = require('../mlproj/core');
const t    = require('../../lib/tools');

// the parameters

const abbrev = t.mandatoryField('abbrev');
const id     = t.optionalField('id', abbrev);
let   dir    = t.mandatoryField('dir').toString();
if ( ! dir.endsWith('/') ) {
    dir += '/';
}

// allow for the user to set these values...?
const global = {
    dry:     false,
    verbose: true
};

const local = {
    abbrev:  abbrev,
    dir:     dir,
    id:      id,
    title:   t.mandatoryField('title'),
    force:   t.optionalField('force',   false),
    name:    t.optionalField('name',    'http://mlproj.org/example/' + abbrev),
    port:    t.optionalField('port',    '8080'),
    version: t.optionalField('version', '0.1.0')
};

// prepare the command

const ctxt    = new ml.Context(global.dry, global.verbose);
const command = new core.NewCommand('create', global, local, ctxt);
const actions = command.prepare();

// execute the command

proj.addConfig(id, 'xproject', proj.configValue('dir', dir));
actions.execute();

view.page(abbrev, actions.done, actions.error, actions.todo, global.verbose);
