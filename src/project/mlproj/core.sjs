"use strict";

(function() {

    // TODO: Not possible to require('mlproj-core') ?!?
    const core = require('../../node_modules/mlproj-core/index');

    module.exports = {};
    Object.keys(core).forEach(k => {
	module.exports[k] = core[k];
    });
}
)();
