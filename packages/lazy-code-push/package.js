Package.describe({
	name: 'simply:lazy-code-push',
	version: '0.0.1',
	summary: 'Ask the user before a hot code push.',
	git: '',
	documentation: 'README.md',
});

Package.onUse(function(api) {
	api.versionsFrom('1.1.0.3');
	api.use('kadira:flow-router', 'client', { weak: true });
	api.use([
		'ecmascript',
		'reload',
		'tracker',
		'session',
	], 'client')
	api.addFiles('lazy-code-push.js', 'client');
});
