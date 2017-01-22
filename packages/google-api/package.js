Package.describe({
	name: 'google-api',
	version: '0.0.1',
	summary: '',
	git: '',
	documentation: 'README.md',
})

Package.onUse(function(api) {
	api.versionsFrom('1.1.0.3')
	api.use([
		'ecmascript',
		'reactive-var',
	], 'client')
	api.addFiles('google-api.js', 'client')
	api.export([
		'GoogleApi',
	], 'client')
})

Package.onTest(function(api) {
	api.use('tinytest')
	api.use('simply:google-api')
	api.addFiles('google-api-tests.js')
})
