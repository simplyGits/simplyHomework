Package.describe({
	name: 'wrts-binding',
	version: '0.0.1',
	summary: 'WRTS binding for simplyHomework.',
	git: '',
	documentation: 'README.md',
});

Npm.depends({
	'wrts': '0.0.0',
});

Package.onUse(function(api) {
	api.versionsFrom('1.1.0.1');

	api.use([
		'erasaur:meteor-lodash',
		'ejson',
	], 'server');
	api.use([
		'coffeescript',
		'templating',
		'handlebars',
	], 'client');

	api.addFiles('wrts-binding.js', 'server');
	api.addFiles([
		'modal.html',
		'modal.coffee',
	], 'client');

	api.export('WrtsBinding', 'server');
});

Package.onTest(function(api) {
	api.use('tinytest');
	api.use('wrts-binding');
	api.addFiles('wrts-binding-tests.js', 'server');
});
