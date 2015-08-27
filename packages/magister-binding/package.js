Package.describe({
	name: 'magister-binding',
	version: '0.0.1',
	summary: 'Magister binding for simplyHomework.',
	git: '',
	documentation: 'README.md',
});

Npm.depends({
	request: '2.61.0',
});

Package.onUse(function(api) {
	api.versionsFrom('1.1.0.1');

	api.use([
		"erasaur:meteor-lodash",
		"simply:magisterjs@1.8.0",
		"ejson",
	], "server");
	api.use([
		"coffeescript",
		"templating",
		"handlebars",
	], "client");

	api.addFiles("magister-binding.js", "server");
	api.addFiles([
		"modal.html",
		"modal.coffee",
	], "client");

	api.export("MagisterBinding", "server");
});

Package.onTest(function(api) {
	api.use('tinytest');
	api.use('magister-binding');
	api.addFiles('magister-binding-tests.js', 'server');
});
