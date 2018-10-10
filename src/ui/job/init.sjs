"use strict";

declareUpdate();

const t   = require('../../lib/tools.xqy');
const v   = require('../../lib/view.xqy');
const job = require('../../job/job-lib.sjs');

const id = fn.head(t.mandatoryField('id'));

job.init(id);
v.redirect(id);
