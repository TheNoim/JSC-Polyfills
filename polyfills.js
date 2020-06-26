(function () {
	global.self = global;
	var Blob = require('blob-polyfill').Blob;
	var {fetch} = require('whatwg-fetch');
	require('formdata-polyfill');
	
	global.Blob = Blob;
	global.fetch = fetch;
	
	require('abortcontroller-polyfill/dist/polyfill-patch-fetch');
})();
