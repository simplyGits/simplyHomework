Package.describe({
	name: 'simply:notices',
	version: '0.0.1',
	summary: 'swagger notices everywhere.',
	git: '',
	documentation: 'README.md',
});

Package.onUse(function(api) {
	api.versionsFrom('1.2.1');
	api.use([
		'coffeescript',
		'check',
		'stevezhu:lodash',
		'mongo',
	]);
	api.use([
		'templating',
		'mquandalle:stylus',
		'handlebars',
	], 'client');
	api.use([
		'reywood:publish-composite',
	], 'server');

	api.addFiles([
		'lib/collections.coffee',
		'lib/schemas.coffee',
		'lib/methods.coffee',
	]);
	api.addFiles([
		'client/noticesManager.coffee',
		'client/notices.html',
		'client/notices.coffee',
		'client/recentGrades/recentGrades.html',
		'client/recentGrades/recentGrades.coffee',
	], 'client');
	api.addFiles([
		'server/security.coffee',
		'server/publish.coffee',
	], 'server');

	api.export([
		'NoticeManager',
		'Notifications',
	]);
});
