"use strict";

declareUpdate();

const t   = require('../../lib/tools.xqy');
const v   = require('../../lib/view.xqy');
const job = require('../../job/job-lib.sjs');

const name   = fn.head(t.mandatoryField('name'));
const desc   = fn.head(t.mandatoryField('desc'));
const lang   = fn.head(t.mandatoryField('lang'));
const target = fn.head(t.mandatoryField('target'));

const result = job.create(name, desc, lang, target);

v.redirect(result.id);
