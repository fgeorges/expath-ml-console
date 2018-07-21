"use strict";

declareUpdate();

const t   = require('../../lib/tools.xqy');
const xqy = require('start.xqy');

const id   = fn.head(t.mandatoryField('id'));
const code = fn.head(t.mandatoryField('code'));
// TODO: Retrieved from the job doc?  Useful to be able to override with params?
// const lang   = fn.head(t.mandatoryField('lang'));
// const target = fn.head(t.mandatoryField('target'));
// TODO: Param dry, as such, is probably not useful.  Still, any way to test code?
// const dry    = getDry(fn.head(t.optionalField('dry', 'false')));

function getUri(coll) {
    const json    = `${coll}/job.json`;
    const xml     = `${coll}/job.xml`;
    const hasJson = fn.docAvailable(json);
    const hasXml  = fn.docAvailable(xml);
    if ( hasJson && hasXml ) {
	throw new Error(`Both XML and JSON version of the job exist: ${xml} and ${json}`);
    }
    else if ( hasJson ) {
	return json;
    }
    else if ( hasXml ) {
	return xml;
    }
    else {
	throw new Error(`None of XML or JSON version of the job exist: ${xml} and ${json}`);
    }
}

function main(id, code) {
    const coll   = `/jobs/${id}`;
    const uri    = getUri(coll);
    const result = {
	id:   id,
	uri:  uri,
	coll: coll
    };

    xqy.start(id, uri, coll, code);

    result.time = xdmp.elapsedTime();
    return result;
}

main(id, code);
