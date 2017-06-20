"use strict";

const xenv = require('../project/xproject/environ.xqy');
const view = require('../project/environments.xqy');
const a    = require('../lib/admin.xqy');
const t    = require('../lib/tools.xqy');

let id = t.mandatoryField('id');

let imports = [];

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

view.page(id, envs);
