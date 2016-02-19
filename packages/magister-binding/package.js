Package.describe({
	name: 'magister-binding',
	version: '0.0.1',
	summary: 'Magister binding for simplyHomework.',
	git: '',
	documentation: 'README.md',
});

Npm.depends({
	request: '2.67.0',
});

Package.onUse(function(api) {
	api.versionsFrom('1.1.0.1');

	api.use([
		'stevezhu:lodash@3.10.1',
		'simply:magisterjs@1.15.2',
		'simply:external-services-connector',
		'ejson',
		'ecmascript',
		'simply:lru',
		'shitdown',
	], 'server');
	api.use([
		'coffeescript',
		'templating',
		'handlebars',
	], 'client');

	api.addFiles('magister-binding.js', 'server');
	api.addFiles([
		'modal.html',
		'modal.coffee',
	], 'client');

	//api.export('MagisterBinding', 'server');
});

Package.onTest(function(api) {
	api.use('tinytest');
	api.use('magister-binding');
	api.addFiles('magister-binding-tests.js', 'server');
});
