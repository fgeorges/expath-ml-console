"use strict";

const proj  = require('../project/proj-lib.xqy');
const ml    = require('../project/mlproj/ml');
const core  = require('../project/mlproj/core');
const xenv  = require('../project/xproject/environ.xqy');
const view  = require('../project/environments.xqy');
const a     = require('../lib/admin.xqy');
const t     = require('../lib/tools.xqy');
const admin = require('/MarkLogic/admin.xqy');

let id = t.mandatoryField('id');

let imports = [];

function allDbs() {
    let res = [];
    const config = admin.getConfiguration();
    for ( let db of admin.getDatabaseIds(config) ) {
        res.push(admin.databaseGetName(config, db));
    }
    return res;
}

let envs = xenv.environs(id).toArray().map(path => {
    let content = a.getFromFilesystem(path);
    let json    = JSON.parse(content);
    if ( json.mlproj && json.mlproj.format ) {
        let slash = path.lastIndexOf('/');
        let from  = slash < 0 ? 0 : slash + 1;
        let file  = path.slice(from);
        return {
            path  : path,
            file  : file,
            title : json.mlproj.title,
            name  : file.slice(0, file.length - 5)
        };
    }
});

// TODO: Values...
const dry     = false;
const verbose = false;
const params  = {};
const force   = {};

const dir     = proj.directory(proj.project(id));
const ctxt    = new ml.Context(dry, verbose, dir);
const project = new core.Project(ctxt, dir);

const details = {
    "@all-dbs":  allDbs()
};

envs.sort((a, b) => {
    return a.name < b.name
        ? -1
        : a.name > b.name
        ? 1
        : 0;
});
envs.forEach(env => {
    let d = {
        databases: [],
        servers:   [],
        sources:   []
    };
    details[env.name] = d;
    // reset, having one global environ not needed in this case
    ctxt.platform.environ = null;
    try {
        const environ = project.environ(env.name, params, force);
        environ.compile(params, force);
        environ.databases().forEach(db => {
            d.databases.push({
                name : db.name
            });
        });
        environ.servers().forEach(srv => {
            d.servers.push({
                name    : srv.name,
                content : srv.content && srv.content.name,
                modules : srv.modules && srv.modules.name
            });
        });
        environ.sources().forEach(src => {
            d.sources.push({
                name : src.name
            });
        });
    }
    catch (err) {
        // TODO: Display an error message...
        d.err = err;
    }
});

view.page(id, envs, JSON.stringify(details));
