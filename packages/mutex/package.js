Package.describe({
	name: 'mutex',
	version: '0.0.1',
	summary: '',
	git: '',
	documentation: 'README.md',
});

Npm.depends({
	'locks': '0.2.2',
});

Package.onUse(function(api) {
	api.versionsFrom('1.4.1.1');
	api.use('ecmascript');
	api.mainModule('mutex.js');
});

Package.onTest(function(api) {
	api.use('ecmascript');
	api.use('tinytest');
	api.use('mutex');
	api.mainModule('mutex-tests.js');
});
