Package.describe({
	name: 'simply:waitgroup',
	version: '0.0.1',
	summary: '',
	git: '',
	documentation: 'README.md',
});

Package.onUse(function(api) {
	api.versionsFrom('1.3.4.1');
	api.use('ecmascript');
	api.mainModule('waitgroup.js', 'server');
});

Package.onTest(function(api) {
	api.use('ecmascript');
	api.use('tinytest');
	api.use('waitgroup');
	api.mainModule('waitgroup-tests.js');
});
