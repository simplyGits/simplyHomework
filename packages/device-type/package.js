Package.describe({
	name: 'device-type',
	version: '0.0.1',
	summary: '',
	git: '',
	documentation: 'README.md',
});

Package.onUse(function(api) {
	api.versionsFrom('1.4.0.1');
	api.use([
		'ecmascript',
		'templating',
	], 'client');
	api.mainModule('device-type.js', 'client');
});
