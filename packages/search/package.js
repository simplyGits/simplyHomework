Package.describe({
	name: 'search',
	version: '0.0.1',
	summary: '/',
	git: '',
	documentation: 'README.md',
})

Package.onUse(function(api) {
	api.versionsFrom('1.2.1')
	api.use([
		'coffeescript',
		'check',
		'stevezhu:lodash',
		'mongo',
	], 'server')
	api.addFiles([
		'search.coffee',
		'methods.coffee',

		'providers/classes.coffee',
		'providers/modals.coffee',
		'providers/projects.coffee',
		'providers/routes.coffee',
		'providers/scholieren.coffee',
		'providers/users.coffee',
	], 'server')
	api.export('Search', 'server')
})

Package.onTest(function(api) {
	api.use('ecmascript')
	api.use('tinytest')
	api.use('search')
	api.addFiles('search-tests.js')
})
