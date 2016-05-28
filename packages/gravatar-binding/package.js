Package.describe({
	name: 'gravatar-binding',
	version: '0.0.1',
	summary: 'Gravatar binding for simplyHomework.',
	git: '',
	documentation: 'README.md',
});

Npm.depends({
	'request': '2.72.0',
	'md5': '2.1.0',
});

Package.onUse(function(api) {
	api.versionsFrom('1.1.0.2');

	api.use([
		'simply:external-services-connector',
		'ecmascript',
		'modules',
	]);

	api.addFiles('info.js');
	api.addFiles('gravatar-binding.js', 'server');
});

Package.onTest(function(api) {
	api.use('tinytest');
	api.use('gravatar-binding');
	api.addFiles('gravatar-binding-tests.js');
});
