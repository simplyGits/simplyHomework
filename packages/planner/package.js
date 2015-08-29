Package.describe({
	name: 'planner',
	version: '0.0.1',
	// Brief, one-line summary of the package.
	summary: 'The plan algorithm of simplyHomework.',
	// URL to the Git repository containing the source code for this package.
	git: '',
	// By default, Meteor will default to using README.md for documentation.
	// To avoid submitting documentation, set this field to null.
	documentation: 'README.md',
});

Npm.depends({
	'js-object-clone': '0.4.2',
});

Package.onUse(function(api) {
	api.versionsFrom('1.1.0.2');

	api.addFiles('planner.js', 'server');

	api.export('HomeworkDescription', 'server');
	api.export('Planner', 'server');
});

Package.onTest(function(api) {
	api.use('tinytest');
	api.use('planner');
	api.addFiles('planner-tests.js');
});
