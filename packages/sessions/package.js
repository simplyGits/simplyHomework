Package.describe({
	name: 'sessions',
	version: '0.0.1',
	summary: 'super simple session management.',
	git: '',
	documentation: 'README.md',
})

Package.onUse(function(api) {
	api.versionsFrom('1.1.0.2')
	api.use(['mongo', 'reactive-var', 'ecmascript'])
	api.addFiles('sessions.js', 'client')
	api.addFiles('sessions.server.js', 'server')

	api.export('Sessions', 'client')
})

Package.onTest(function(api) {
	api.use('tinytest')
	api.use('sessions')
	api.addFiles('sessions-tests.js')
})
