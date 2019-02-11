"use strict";

module.exports = (() => {

    const t = require('/lib/tools.xqy');

    function query(db, fun) {
        return xdmp.invokeFunction(fun, {database: t.databaseId(db)});
    }

    function mandatoryField(name) {
        const val = t.mandatoryField(name);
        if ( fn.exists(fn.tail(val)) ) {
            throw new Error(`Mandatory field ${name} has more than 1 value: ${val}`);
        }
        return fn.head(val);
    }

    function optionalField(name, dflt) {
        const val = t.optionalField(name, dflt);
        if ( fn.exists(fn.tail(val)) ) {
            throw new Error(`Optional field ${name} has more than 1 value: ${val}`);
        }
        return fn.head(val);
    }

    return {
        query:          query,
        mandatoryField: mandatoryField,
        optionalField:  optionalField
    };

})();
