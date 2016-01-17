Package.describe({
	name: 'notifications-manager',
	version: '0.0.1',
	summary: '',
	git: '',
	documentation: 'README.md',
});

Package.onUse(function(api) {
	api.versionsFrom('1.2.1');
	api.use('coffeescript');
	api.addFiles('client/notificationsManager.coffee', 'client');
	api.export('NotificationsManager', 'client');
});

Package.onTest(function(api) {
	api.use('ecmascript');
	api.use('tinytest');
	api.use('notifications-manager');
	api.addFiles('notifications-manager-tests.js');
});
