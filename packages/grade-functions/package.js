Package.describe({
	name: 'grade-functions',
	version: '0.0.1',
	summary: '',
	git: '',
	documentation: 'README.md',
});

Package.onUse(function(api) {
	api.versionsFrom('1.2.1');
	api.use([
		'zardak:livescript',
		'check',
	]);
	api.addFiles([
		'lib/init.ls',
		'lib/functions.ls',
	]);
});
