// simple onesignal wrapper until the npm modules are more mature.

Package.describe({
	name: 'onesignal',
	version: '0.0.1',
	summary: 'simple onesignal wrapper',
	git: '',
	documentation: 'README.md',
});

Package.onUse(function(api) {
	api.versionsFrom('1.4');
	api.use('ecmascript');
	api.use([
		'check',
		'http',
	], 'server');

	api.mainModule('main.js');
});
