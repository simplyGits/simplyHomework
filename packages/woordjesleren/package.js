Package.describe({
	name: 'simply:woordjesleren',
	version: '0.0.1',
	summary: 'Simple serverside library for woordjesleren.nl.',
	git: '',
	//git: 'https://github.com/simplyGits/WoordjesLeren',
	documentation: 'README.md',
});

Npm.depends({
	'cheerio': '0.20.0',
});

Package.onUse(function(api) {
	api.versionsFrom('1.1.0.3');
	api.use([
		'ecmascript',
		'http',
		'stevezhu:lodash@3.10.1',
	], 'server');
	api.use('search', 'server', { weak: true });
	api.addFiles('woordjesleren.js', 'server');
	api.export('WoordjesLeren', 'server');
});

Package.onTest(function(api) {
	api.use('tinytest');
	api.use('woordjesleren');
	api.addFiles('woordjesleren-tests.js');
});
