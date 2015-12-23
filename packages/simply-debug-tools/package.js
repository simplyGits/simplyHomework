Package.describe({
	name: 'simply-debug-tools',
	version: '0.0.1',
	// Brief, one-line summary of the package.
	summary: 'Debug utilities for simplyHomework.',
	// URL to the Git repository containing the source code for this package.
	git: '',
	// By default, Meteor will default to using README.md for documentation.
	// To avoid submitting documentation, set this field to null.
	documentation: 'README.md',
	//debugOnly: true,
});

Package.onUse(function(api) {
	api.versionsFrom('1.0');
	api.addFiles('simply-debug-tools.js');
	api.export('Debug');
});

Package.onTest(function(api) {
	api.use('tinytest');
	api.use('simply-debug-tools');
	api.addFiles('simply-debug-tools-tests.js');
});
