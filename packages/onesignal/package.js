// simple onesignal wrapper until the npm modules are more mature.

Package.describe({
	name: 'onesignal',
	version: '0.0.1',
	summary: 'simple onesignal wrapper',
	git: '',
	documentation: 'README.md',
});

Npm.depends({
	'request': '2.74.0',
});

Package.onUse(function(api) {
	api.versionsFrom('1.4');
	api.use('ecmascript');

	api.mainModule('client.js', 'client');

	api.use([
		'check',
		'http',
		'meteorhacks:picker',
	], 'server');
	api.mainModule('server.js', 'server');
});
