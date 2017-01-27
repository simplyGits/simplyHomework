Package.describe({
	name: 'privacy',
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
		'coffeescript',
		'underscore',
		'modules',
	]);
	api.use([
		'templating',
	], 'client');

	api.mainModule('client/main.coffee', 'client');
	api.mainModule('server/main.coffee', 'server');
});

Package.onTest(function(api) {
	api.use('tinytest');
	api.use('privacy');
	api.addFiles('privacy-tests.js');
});
