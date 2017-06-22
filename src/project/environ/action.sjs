"use strict";

const core = require('../mlproj/core');
// WTF is happening to path resolution?!?
const lib  = require('../../project/environ/environ-lib');
const t    = require('../../lib/tools.xqy');

const project = fn.head(t.mandatoryField('project'));
const environ = fn.head(t.mandatoryField('environ'));
const action  = fn.head(t.mandatoryField('action'));

lib.withProject(
    project,
    environ,
    (proj, platform, display) => {
        const ctor = core.actions[action];
        if ( ! ctor ) {
            throw new Error('Action class does not exist: ' + action);
        }
        const a = new ctor();
        a.fromValues({
            msg  : fn.head(t.mandatoryField('msg')),
            api  : fn.head(t.mandatoryField('api')),
            url  : fn.head(t.mandatoryField('url')),
            verb : fn.head(t.mandatoryField('verb')),
            data : fn.head(t.optionalField('data', '')),
            json : fn.head(t.optionalField('json', 'false')) === 'true'
        });
        return a.execute(platform);
    },
    (err) => {
        return t.respondInternalError(err);
    });
