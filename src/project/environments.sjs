"use strict";

const proj  = require('../project/proj-lib.xqy');
const ml    = require('../project/mlproj/ml');
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
const dry      = false;
const verbose  = false;
const params   = {};
const force    = {};
const platform = new ml.Platform(dry, verbose);
const dir      = proj.directory(proj.project(id));
let   details  = {
    "@all-dbs":  allDbs()
};
envs.forEach(env => {
    let d = {
	databases: [],
	servers:   []
    };
    details[env.name] = d;
    const p = platform.project(null, env.path, dir, params, force);
    p.space.databases().forEach(db => {
	d.databases.push({
	    name : db.name
	});
    });
    p.space.servers().forEach(srv => {
	d.servers.push({
	    name    : srv.name,
	    content : srv.content && srv.content.name,
	    modules : srv.modules && srv.modules.name
	});
    });
});

view.page(id, envs, JSON.stringify(details));
