Package.describe({
	name: 'admin',
	version: '0.0.1',
	summary: 'admin api endpoints',
	git: '',
	documentation: 'README.md',
})

Package.onUse(function(api) {
	api.versionsFrom('1.2.1')
	api.use([
		'ecmascript',
		'tmeasday:publish-counts',
		'check',
		'mongo',
	], 'server')
	api.addFiles('server/publish.js', 'server')
})
