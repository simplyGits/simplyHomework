Package.describe({
	name: 'ms',
	version: '0.0.1',
	summary: 'functions to convert about anything to ms.',
	git: '',
	documentation: 'README.md',
});

Package.onUse(function(api) {
	api.versionsFrom('1.2.1');
	api.use('ecmascript');
	api.addFiles('ms.js');
	api.export('ms');
});
