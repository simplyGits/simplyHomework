Package.describe({
	name: 'viewport-units-buggyfill',
	version: '0.6.0',
	summary: 'Making viewport units (vh|vw|vmin|vmax) work properly in Mobile Safari.',
	git: 'https://github.com/rodneyrehm/viewport-units-buggyfill',
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
