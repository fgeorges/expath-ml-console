"use strict";

(function() {

    const core  = require('./core');
    const a     = require('../../lib/admin.xqy');

    class MarkLogic extends core.Platform
    {
	constructor(dry, verbose) {
	    super(dry, verbose);
	}

        resolve(href, base) {
	    return fn.resolveUri(href, base);
        }

        read(path) {
	    const content = a.getFromFilesystem(path);
	    if ( ! content ) {
		// TODO: Define what platform-independent error to throw when
		// `path` does not exist...
		let err = new Error('File does not exist: ' + path);
		err.code = 'ENOENT';
		throw err;
	    }
	    return content;
        }

        xml(path, callback) {
            const content = this.read(path);
	    const result  = xdmp.unquote(content);
	    callback(result);
        }
    }

    module.exports = {
	MarkLogic : MarkLogic
    };
}
)();
