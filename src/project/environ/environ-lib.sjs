"use strict";

(function() {

    const ml   = require('../mlproj/ml');
    const core = require('../mlproj/core');
    const proj = require('../../project/proj-lib.xqy');

    function withProject(id, environ, success, error) {
        try {
            const dir = proj.directory(proj.project(id));

            // TODO: Values...
            const dry     = false;
            const verbose = true;
            const ctxt    = new ml.Context(dry, verbose, dir);

            // TODO: Values...
            const params = {};
            const force  = {};

            // the project
            const p = new core.Project(ctxt, dir);
            const e = p.environ(environ, params, force);

            return success(ctxt, e);
        }
        catch (err) {
            if ( err.mlerr ) {
                //console.log(err);
                return error(err);
            }
            else {
                let obj = {
                    name    : err.name,
                    message : err.message,
                    stack   : err.stack
                };
                //console.log(obj);
                return error(obj);
            }
        }
    }

    function loadDeploy(project, environ, srcSet, srcPath, target, cmd, view, error) {
        const addSource = (ctxt, args) => {
            if ( srcSet && srcPath ) {
                throw new Error('Source set and source path both provided');
            }
            else if ( srcSet ) {
                args.srcset = srcSet;
            }
            else if ( srcPath ) {
                const path = ctxt.platform.resolve(srcPath);
                if ( ctxt.platform.isDirectory(path) ) {
                    args.directory = srcPath;
                }
                else {
                    args.document = srcPath;
                }
            }
            else {
                throw new Error('None of source set and source path provided');
            }
        };

        const addTarget = (ctxt, args) => {
            if ( target.startsWith('db:') ) {
                args.database = target.slice('db:'.length);
            }
            else if ( target.startsWith('srv:') ) {
                args.server = target.slice('srv:'.length);
            }
            else if ( target.startsWith('other:') ) {
                args.forceDb = target.slice('other:'.length);
            }
            else {
                throw new Error('Internal error: target is neither db:*, srv:* or other:* - ' + target);
            }
        };

        return withProject(
            project,
            environ,
            (ctxt, env) => {
                // the command args
                var cmdArgs = {};
                addSource(ctxt, cmdArgs);
                addTarget(ctxt, cmdArgs);
                // prepare the command
                const command = new cmd({}, cmdArgs, ctxt, env);
                const actions = command.prepare();
                // draw the actions, which will be orchestrated by the client
                return view(cmdArgs, actions.todo.map(a => a.toValues()));
            },
            error);
    }

    module.exports = {
        withProject : withProject,
        loadDeploy  : loadDeploy
    };
}
)();
