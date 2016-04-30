Package.describe({
	name: '2fa',
	version: '0.0.1',
	summary: '',
	git: '',
	documentation: 'README.md',
});

Npm.depends({
	'speakeasy': '2.0.0',
	'qrcode': '0.4.2',
});

Package.onUse(function(api) {
	api.versionsFrom('1.3.2.4');
	api.use([
		'ecmascript',
		'meteorhacks:picker',
		'accounts-base',
		'check',
	], 'server');
	api.mainModule('2fa.js', 'server');
});

Package.onTest(function(api) {
	api.use('ecmascript');
	api.use('tinytest');
	api.use('2fa');
	api.mainModule('2fa-tests.js');
});
