"use strict";

module.exports = (() => {

    const t = require('/lib/tools.xqy');

    function query(db, fun) {
        return xdmp.invokeFunction(fun, {database: t.databaseId(db)});
    }

    return {
        query: query
    };

})();
