Package.describe({
	name: 'emails',
	version: '0.0.1',
	summary: '',
	git: '',
	documentation: 'README.md',
});

Npm.depends({
	'simplyemail': '1.0.8',
	'dedent-js': '1.0.1',
});

Package.onUse(function(api) {
	api.versionsFrom('1.2.1');
	api.use([
		'ecmascript',
		'modules',
		'promise',
		'check',
		'email',
	], 'server');
	api.mainModule('emails.js', 'server');
});

Package.onTest(function(api) {
	api.use('ecmascript');
	api.use('tinytest');
	api.use('emails');
	api.addFiles('emails-tests.js');
});
