"use strict";

(function() {

    const core = require('./core');

    module.exports = {};
    Object.keys(core).filter(k => k.endsWith('Command')).forEach(k => {
	module.exports[k] = core[k];
    });
}
)();
