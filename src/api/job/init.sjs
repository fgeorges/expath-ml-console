"use strict";

declareUpdate();

const t   = require('../../lib/tools.xqy');
const job = require('../../job/job-lib.sjs');

const id = fn.head(t.mandatoryField('id'));

const result = job.init(id);
result.time = xdmp.elapsedTime();
result;
