"use strict";

(function() {

    const core  = require('./core');
    // WTF is happening to path resolution?!?
    const utils = require('../../project/mlproj/mlproj-utils.xqy');
    const disp  = require('../../project/mlproj/display.xqy');
    const a     = require('../../lib/admin.xqy');

    class Platform extends core.Platform
    {
	constructor(dry, verbose) {
	    super(dry, verbose);
	}

        resolve(href, base) {
	    return new String(fn.resolveUri(href, base));
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

        projectXml(path) {
	    return utils.doProjectXml(path);
        }

        info(msg) {
            console.log('mlproj: ' + msg);
        }

        get(api, url, error, success) {
            var url  = this.url(api, url);
            var user = this.space.param('@user');
            var pwd  = this.space.param('@password');
            if ( ! user ) {
                throw new Error('No user in space');
            }
            if ( ! pwd ) {
                throw new Error('No pwd in space (TODO: Allow to pass via form values...)');
            }
            var options = {
                headers: {
                    Accept: 'application/json'
                },
		authentication: {
		    // TODO: Set method accordingly...
		    method   : 'digest',
		    username : user,
		    password : pwd
		}
            };
            var resp = xdmp.httpGet(url, options);
	    var info = fn.head(resp);
	    var body = fn.head(fn.tail(resp));
            if ( info.code === 200 ) {
                return JSON.parse(body);
            }
            else if ( info.code === 404 ) {
                return;
            }
            else {
                throw new Error('Error retrieving entity: ' + (body.errorResponse
                                ? body.errorResponse.message : body));
            }
        }

	// TODO: Display specific, to be removed...
        bold(s) {
            return s;
        }

	// TODO: Display specific, to be removed...
        yellow(s) {
            return s;
        }

	// TODO: Display specific, to be removed...
        red(s) {
            return s;
        }

	// TODO: Display specific, to be removed...
        green(s) {
            return s;
        }

	// TODO: Display specific, to be removed...
        log(msg) {
            console.log(msg);;
        }

	// TODO: Display specific, to be removed...
        warn(msg) {
            console.log(msg);;
        }

	// TODO: Handle proper configuration...
        config(name) {
        }

	// TODO: Handle proper configuration...
        configs() {
	    return [];
        }
    }

    class Display extends core.Display
    {
	constructor() {
	    super();
	    this.content = [];
	}

	save(elems) {
	    for ( let e of elems ) {
		this.content.push(e);
	    }
	}

        database(name, id, schema, security, triggers, forests, props) {
	    let sch = schema   && schema.name;
	    let sec = security && security.name;
	    let tri = triggers && triggers.name;
            this.save(disp.database(
		name, id, sch, sec, tri, forests, props));
	}

        server(name, id, group, content, modules, props) {
	    let c = content && content.name;
	    let m = modules && modules.name;
            this.save(disp.server(
		name, id, group, c, m, props));
	}

        project(code, configs, title, name, version) {
            this.save(disp.project(
		code, configs, title, name, version));
	}

        environ(envipath, title, desc, host, user, password, srcdir, mods, params, imports) {
            this.save(disp.environ(
		envipath, title, desc, host, user, password, srcdir, mods, params, imports));
	}

        check(indent, msg, arg) {
            this.save(disp.check(indent, msg, arg));
	}

        add(indent, verb, msg, arg) {
            this.save(disp.add(indent, verb, msg, arg));
	}

        remove(indent, verb, msg, arg) {
            this.save(disp.remove(indent, verb, msg, arg));
	}
    }

    module.exports = {
	Platform : Platform,
	Display  : Display
    };
}
)();
