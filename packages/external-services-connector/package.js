Package.describe({
	name: 'simply:external-services-connector',
	version: '0.0.1',
	// Brief, one-line summary of the package.
	summary: '',
	// URL to the Git repository containing the source code for this package.
	git: '',
	// By default, Meteor will default to using README.md for documentation.
	// To avoid submitting documentation, set this field to null.
	documentation: 'README.md',
});

Package.onUse(function(api) {
	api.versionsFrom('1.2.1');
	api.use([
		'stevezhu:lodash@3.10.1',
		'coffeescript',
		'check',
		'modules',
		'mongo',
		'accounts-base',
	]);
	api.use([
		'ejson',
		'meteorhacks:picker',
		'ms',
		'mutex',
		'simply:waitgroup',
		'privacy',
	], 'server');

	api.mainModule('client/connector.coffee', 'client');
	api.mainModule('server/connector.coffee', 'server');
});

Package.onTest(function(api) {
	api.use('ecmascript');
	api.use('tinytest');
	api.use('simply:external-services-connector');
	api.addFiles('external-services-connector-tests.js');
});
