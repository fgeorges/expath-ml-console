xdmp.setResponseContentType('application/json');

// fn:error((),
//      '&#10;Filename: ' || xdmp:get-request-field-filename('file')
//   || '&#10;User:     ' || xdmp:get-request-user()
//   || '&#10;Username: ' || xdmp:get-request-username()
//   || '&#10;User:     ' || xdmp:get-current-user()
//   || '&#10;User ID:  ' || xdmp:get-current-userid()!xs:string(.))

var bodies = xdmp.getRequestField('files');

xdmp.toJSON( { 
    "files": [
        {
            "name": "NOTES.txt",
            "size": 123,
            "error": "Filetype not allowed"
        },
        {
            "Filename": xdmp.getRequestFieldFilename('file'),
            "Filenames": xdmp.getRequestFieldFilename('files'),
            "Filenamess": xdmp.getRequestFieldFilename('files[]'),
            "User": xdmp.getRequestUser(),
            "Username": xdmp.getRequestUsername(),
            "User2": xdmp.getCurrentUser(),
            "User ID": xdmp.getCurrentUserid()
        },
        {
            "headers": xdmp.getRequestHeaderNames().toArray().map(
                function(n) {
                    return { "name": n, "value": xdmp.getRequestHeader(n) };
                }),
            "fields": xdmp.getRequestFieldNames().toArray().map(
                function(n) {
                    return { "name": n, "value": xdmp.getRequestField(n) };
                }),
            "body": xdmp.getRequestBody()
        },
        xdmp.getRequestFieldFilename('files').toArray().map(
            function(n, i) {
                var o = {};
                var t = bodies[i].nodeType;
                if ( t == 9 ) { // doc node
                    
                }
                else if ( t == 13 ) { // binary node
                    
                }
                else {
                    throw "Error";
                }
                o[n] = bodies[i].nodeType;
                // o[n] = bodies[i].toObject();
                return o;
            }
        )
    ]
} );
