Package.describe({
	name: 'simply:lazy-code-push',
	version: '0.0.1',
	summary: 'Ask the user before a hot code push.',
	git: '',
	documentation: 'README.md',
});

Package.onUse(function(api) {
	api.versionsFrom('1.1.0.3');
	api.use('reload', 'client');
	api.use('tracker', 'client');
	api.addFiles('lazy-code-push.js', 'client');
});
