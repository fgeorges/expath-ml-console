"use strict";

(function() {

    const core   = require('./core');
    const mmatch = require('../../node_modules/minimatch/minimatch.js');
    // WTF is happening to path resolution?!?
    const utils  = require('../../project/mlproj/mlproj-utils.xqy');
    const disp   = require('../../project/mlproj/display.xqy');
    const a      = require('../../lib/admin.xqy');
    const bin    = require('../../lib/binary.xqy');

    /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * The context implementation for MarkLogic.
     */

    class Context extends core.Context
    {
        constructor(dry, verbose, cwd) {
            // TODO: Support config files...
            let conf = null;
            // instantiate the base object
            super(new Display(verbose), new Platform(cwd), conf, dry, verbose);
        }
    }

    /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * The platform implementation for MarkLogic.
     */

    class Platform extends core.Platform
    {
        constructor(cwd) {
            super(cwd);
        }

        corePackage() {
            return a.getFromDatabase(
                xdmp.modulesDatabase(),
                '/node_modules/mlproj-core/package.json');
        }

        newMinimatch(pattern, options) {
            return new mmatch.Minimatch(pattern, options);
        }

        resolve(href, base) {
            let res = fn.resolveUri(href, base || this.cwd);
            return new String(res);
        }

        read(path) {
            const content = a.getFromFilesystem(path);
            if ( ! content ) {
                throw core.error.noSuchFile(path);;
            }
            return content;
        }

        projectXml(path) {
            return utils.doProjectXml(path);
        }

        credentials() {
            // set in Environ ctor, find a nicer way to pass the info
            if ( ! this.environ ) {
                throw new Error('No environ set on the platform for credentials');
            }
            var user = this.environ.param('@user');
            var pwd  = this.environ.param('@password');
            if ( ! user ) {
                throw new Error('No user in environ');
            }
            if ( ! pwd ) {
                throw new Error('No pwd in environ (TODO: Allow to pass via form values...)');
            }
            var options = {
                authentication: {
                    // TODO: Set method accordingly...
                    method   : 'digest',
                    username : user,
                    password : pwd
                },
                headers: {
                    Accept: 'application/json'
                }
            };
            return options;
        }

        get(api, url) {
            var url     = this.url(api, url);
            var options = this.credentials();
            var resp    = xdmp.httpGet(url, options);
            var info    = fn.head(resp);
            var body    = fn.head(fn.tail(resp));
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

        post(api, url, data, type) {
            var url     = this.url(api, url);
            var options = this.credentials();
            var resp;
            if ( bin.isBinary(data) ) {
                options.headers['Content-Type'] = type;
                resp = xdmp.httpPost(url, options, data);
            }
            else {
                if ( data && type ) {
                    options.headers['Content-Type'] = type;
                    options.data                    = data;
                }
                else if ( data ) {
                    options.headers["Content-Type"] = 'application/json';
                    options.data                    = JSON.stringify(data);
                }
                else {
                    options.headers['Content-Type'] = 'application/x-www-form-urlencoded';
                }
                resp = xdmp.httpPost(url, options);
            }
            var info = fn.head(resp);
            var body = fn.head(fn.tail(resp));
            if ( info.code === ((data && ! type) ? 201 : 200) ) {
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
            if ( data && type ) {
                options.headers['Content-Type'] = type;
                options.data                    = data;
            }
            else if ( data ) {
                options.headers["Content-Type"] = 'application/json';
                options.data                    = JSON.stringify(data);
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

        boundary() {
            return sem.uuidString();
        }

        multipart(boundary, parts) {
            let res = xdmp.multipartEncode(
                boundary,
                parts.map(part => {
                    return { headers: {
                        "Content-Disposition": 'attachment; filename="' + part.uri + '"'
                    }};
                }),
                // read everything as binary, so exactly as it is on the disk
                parts.map(part => xdmp.externalBinary(part.path)));
            // add the property length to the binary node (used in the action message)
            let len = xdmp.binarySize(res);
            res.length = len;
            return res;
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
                        res.isdir = true;
                    }
                    return res;
                });
        }

        isDirectory(path) {
            try {
                xdmp.filesystemDirectory(path);
                return true;
            }
            catch (err) {
                // TODO: Differentiate between not a dir and not exist (= noSuchFile()...)
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

    /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * The display implementation for MarkLogic.
     */

    class Display extends core.Display
    {
        constructor(verbose) {
            super(verbose);
            this.content = [];
        }

        save(elems) {
            for ( let e of elems ) {
                this.content.push(e);
            }
        }

        // TODO: FIXME: ...
        info(msg) {
            console.log('mlproj: ' + msg);
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

        source(name, props) {
            this.save(disp.source(
                name, props));
        }

        mimetype(name, props) {
            this.save(disp.mimetype(
                name, props));
        }

        project(code, configs, title, name, version) {
            this.save(disp.project(
                code, configs, title, name, version));
        }

        environ(envipath, title, desc, host, user, password, params, imports) {
            this.save(disp.environ(
                envipath, title, desc, host, user, password, params, imports));
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

        error(e) {
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
            if ( this.verbose ) {
                this.save(disp.toImplement('Stacktrace:'));
                this.save(disp.code(e.stack));
            }
        }
    }

    module.exports = {
        Context  : Context,
        Platform : Platform,
        Display  : Display
    };
}
)();
