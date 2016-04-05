Package.describe({
	name: 'service-messages',
	version: '0.0.1',
	summary: '',
	git: '',
	documentation: 'README.md',
})

Package.onUse(function(api) {
	api.versionsFrom('1.3')
	api.use([
		'mongo',
		'ecmascript',
	])
	api.use([
		'simply:notices',
		'templating',
		'handlebars',
	], 'client')
	api.use([
		'check',
	], 'server')

	api.addFiles([
		'client/notice.html',
	], 'client')

	api.mainModule('server.js', 'server')
	api.mainModule('client.js', 'client')
})
