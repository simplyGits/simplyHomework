Package.describe({
	name: 'magister-binding',
	version: '0.0.1',
	summary: 'Magister binding for simplyHomework.',
	git: '',
	documentation: 'README.md',
});

Npm.depends({
	'marked': '0.3.6',
	'lru-cache': '4.0.2',
	'magister.js': '1.24.1',
});

Package.onUse(function(api) {
	api.versionsFrom('1.1.0.1');

	api.use([
		'simply:external-services-connector',
		'ecmascript',
		'modules',
	]);
	api.use([
		'stevezhu:lodash@3.10.1',
		'ejson',
		'ms',
		'mutex',
	], 'server');
	api.use([
		'coffeescript',
		'templating',
		'handlebars',
		'reactive-var',
	], 'client');

	api.addFiles('info.js');
	api.addFiles('magister-binding.js', 'server');
	api.addFiles([
		'modal.html',
		'modal.coffee',
	], 'client');
});

Package.onTest(function(api) {
	api.use('tinytest');
	api.use('magister-binding');
	api.addFiles('magister-binding-tests.js', 'server');
});
