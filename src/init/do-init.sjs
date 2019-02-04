"use strict";

declareUpdate();

const t   = require('/lib/tools.xqy');
const v   = require('/lib/view.xqy');
const lib = require('./lib-init.xqy');

function insert(uri, node) {
    // TODO: Set permissions properly.
    xdmp.documentInsert(uri, node);
}

// the config file itself
insert(lib.configUri, lib.makeConfig());
v.redirect('init');
