"use strict";

(function() {

    const core  = require('./core');
    // WTF is happening to path resolution?!?
    const utils = require('../../project/mlproj/mlproj-utils.xqy');
    const disp  = require('../../project/mlproj/display.xqy');
    const a     = require('../../lib/admin.xqy');

    class Platform extends core.Platform
    {
        constructor(dry, verbose, cwd) {
            super(dry, verbose);
	    this.cwd = cwd;
        }

        resolve(href, base) {
	    if ( ! base ) {
		base = this.cwd;
	    }
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

        credentials() {
            var user = this.space.param('@user');
            var pwd  = this.space.param('@password');
            if ( ! user ) {
                throw new Error('No user in space');
            }
            if ( ! pwd ) {
                throw new Error('No pwd in space (TODO: Allow to pass via form values...)');
            }
            var options = {
                authentication: {
                    // TODO: Set method accordingly...
                    method   : 'digest',
                    username : user,
                    password : pwd
                }
            };
            return options;
        }

        get(api, url) {
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

        post(api, url, data) {
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
                authentication: {
                    // TODO: Set method accordingly...
                    method   : 'digest',
                    username : user,
                    password : pwd
                },
                headers: {
                    "Content-Type": 'application/x-www-form-urlencoded'
                }
            };
            if ( data ) {
                options.headers["Content-Type"] = 'application/json';
                options.data                    = JSON.stringify(data);
            }
            var resp = xdmp.httpPost(url, options);
            var info = fn.head(resp);
            var body = fn.head(fn.tail(resp));
            if ( info.code === (data ? 201 : 200) ) {
                return;
            }
            else {
                throw new Error('Entity not created: ' + (body.errorResponse
                                ? body.errorResponse.message : body));
            }
        }

        put(api, url, data, type) {
            var url     = this.url(api, url);
            var options = this.credentials();
            options.headers = {
                Accept: 'application/json'
            };
            if ( data ) {
                if ( type ) {
                    options.headers['Content-Type'] = type;
                    options.data                    = data;
                }
                else {
                    options.headers["Content-Type"] = 'application/json';
                    options.data                    = JSON.stringify(data);
                }
            }
            else {
                options.headers['Content-Type'] = 'application/x-www-form-urlencoded';
            }
            var resp = xdmp.httpPut(url, options);
            var info = fn.head(resp);
            var body = fn.head(fn.tail(resp));
            // XDBC PUT /insert returns 200
            if ( info.code === 200 || info.code === 201 || info.code === 204 ) {
                return;
            }
            // when operation needs a server restart
            else if ( info.code === 202 ) {
                if ( ! body.root.restart ) {
                    throw new Error('202 returned NOT for a restart reason?!?');
                }
                return Date.parse(body.root.restart['last-startup'][0].value);
            }
            else {
                throw new Error('Entity not updated: ' + (body.errorResponse
                                ? body.errorResponse.message : body));
            }
        }

        // TODO: Do something different when target is "localhost"?
        restart(last) {
            var ping;
            var body;
            var num = 1;
            do {
                xdmp.sleep(1000);
                if ( ! (num % 3) ) {
                    // TODO: Says "Still waiting...", somehow?
                }
                try {
                    var res = xdmp.httpGet(this.url('admin', '/timestamp'), this.credentials());
                    ping = fn.head(res);
                    body = fn.head(fn.tail(res));
                }
                catch ( err ) {
                    ping = err;
                }
            }
            while ( ++num < 10 && (ping.code === 503) );
            if ( ping.code !== 200 ) {
                throw new Error('Error waiting for server restart: ' + num + ' - ' + ping);
            }
            var now = Date.parse(body);
            if ( last >= now ) {
                throw new Error('Error waiting for server restart: ' + last + ' - ' + now);
            }
        }

        dirChildren(dir) {
	    const path = this.resolve(dir);
            return xdmp.filesystemDirectory(path)
		.filter(child => {
		    return child.type === 'file' || child.type === 'directory'
		})
		.map(child => {
		    var res = {
			name : child.filename,
			path : child.pathname
		    };
		    if ( child.type === 'directory' ) {
                        res.files = [];
		    }
		    return res;
		});
        }

        isDirectory(path) {
            try {
		xdmp.filesystemDirectory(dir);
		return true;
	    }
	    catch (err) {
		return false;
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

        error(e, verbose) {
            switch ( e.name ) {
            case 'server-no-content':
                this.save(disp.toImplement(
                    'Error: The server ' + e.server + ' has no content DB.'));
                this.save(disp.toImplement(
                    'Are you sure you want to load documents on it?  Check your environ file.'));
            case 'server-no-modules':
                this.save(disp.toImplement(
                    'Error: The server ' + e.server + ' has no modules DB.'));
                this.save(disp.toImplement(
                    'There is no need to deploy when server modules are on the filesystem.'));
            default:
                this.save(disp.toImplement('Error: ' + e.message));
            }
            if ( verbose ) {
                this.save(disp.toImplement('Stacktrace:'));
                this.save(disp.code(e.stack));
            }
        }
    }

    module.exports = {
        Platform : Platform,
        Display  : Display
    };
}
)();
