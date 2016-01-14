Package.describe({
	name: 'schedule-functions',
	version: '0.0.1',
	summary: '',
	git: '',
	documentation: 'README.md',
});

Package.onUse(function(api) {
	api.versionsFrom('1.2.1');
	api.use('zardak:livescript');
	api.addFiles([
		'lib/init.ls',
		'lib/functions.ls',
	]);
});

Package.onTest(function(api) {
	api.use('ecmascript');
	api.use('tinytest');
	api.use('schedule-functions');
	api.addFiles('schedule-functions-tests.js');
});
