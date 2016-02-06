Package.describe({
	name: 'sessions',
	version: '0.0.1',
	summary: 'simple session management',
	git: '',
	documentation: 'README.md',
})

Package.onUse(function(api) {
	api.versionsFrom('1.1.0.2')
	api.use([
		'mongo',
		'reactive-var',
		'ecmascript',
	])
	api.use([
		'tracker',
	], 'client')
	api.addFiles('sessions.js', 'client')
	api.addFiles('sessions.server.js', 'server')

	api.export('Sessions', 'client')
})
