// To be used in conjunction with another environment, for the connect info:
//
//     > mlproj -e dev/test load -b test

module.exports = function() {
    return {
        mlproj: {
            format: '0.1',
            sources: [{
                name:   'data',
                dir:    'test/data',
                target: 'test'
            }],
            databases: [{
	        id:   'test',
	        name: '@{code}-test-content'
            }]
        }
    };
};
