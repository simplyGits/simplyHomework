Package.describe({
	name: '2fa',
	version: '0.0.1',
	summary: '',
	git: '',
	documentation: 'README.md',
})

Npm.depends({
	'speakeasy': '2.0.0',
})

Package.onUse(function(api) {
	api.versionsFrom('1.3.2.4')
	api.use('ecmascript')
	api.use([
		'templating',
		'handlebars',
		'reactive-var'
	], 'client')
	api.use([
		'meteorhacks:picker',
		'accounts-base',
		'check',
		'stevezhu:lodash@3.10.1',
	], 'server')
	api.addFiles([
		'modal/modal.html',
		'modal/modal.css',
		'modal/modal.js',
	], 'client')
	api.mainModule('2fa.js', 'server')
})

Package.onTest(function(api) {
	api.use('ecmascript')
	api.use('tinytest')
	api.use('2fa')
	api.mainModule('2fa-tests.js')
})
