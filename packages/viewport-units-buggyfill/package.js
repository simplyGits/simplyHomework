Package.describe({
	name: 'viewport-units-buggyfill',
	version: '0.5.5',
	// Brief, one-line summary of the package.
	summary: 'Making viewport units (vh|vw|vmin|vmax) work properly in Mobile Safari.',
	// URL to the Git repository containing the source code for this package.
	git: 'https://github.com/rodneyrehm/viewport-units-buggyfill',
	// By default, Meteor will default to using README.md for documentation.
	// To avoid submitting documentation, set this field to null.
	documentation: 'dist/README.md',
});

Package.onUse(function(api) {
	api.versionsFrom('1.2.1');
	api.addFiles([
		'dist/viewport-units-buggyfill.hacks.js',
		'dist/viewport-units-buggyfill.js',
		'viewport-units-buggyfill.js',
	], 'client');
});
