Package.describe({
	name: 'themes',
	version: '0.0.1',
	// Brief, one-line summary of the package.
	summary: '',
	// URL to the Git repository containing the source code for this package.
	git: '',
	// By default, Meteor will default to using README.md for documentation.
	// To avoid submitting documentation, set this field to null.
	documentation: 'README.md'
});

Package.onUse(function(api) {
	api.versionsFrom('1.2.1');
	api.use([
		'stylus'
	]);
	api.use([
		'meteorhacks:inject-initial',
		'webapp',
		'underscore',
	], 'server');
	api.use('appcache', 'server', { weak: true });
	api.addFiles('themes/paarse-vrijdag.styl')
	api.addFiles('themes.js', 'server');
});

Package.onTest(function(api) {
	api.use('ecmascript');
	api.use('tinytest');
	api.use('themes');
	api.addFiles('themes-tests.js');
});
