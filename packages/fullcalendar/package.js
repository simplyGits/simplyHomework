Package.describe({
	name: 'simply:fullcalendar',
	version: '2.9.1',
	summary: 'vanilla fullcalendar packaged for Meteor, only loads on desktop machines.',
	git: '',
	documentation: 'README.md',
});

Package.onUse(function(api) {
	api.versionsFrom('1.1.0.3');

	api.use([
		'meteorhacks:inject-initial',
		'webapp',
		'ecmascript',
	], 'server');
	api.use('appcache', 'server', { weak: true });
	api.use('momentjs:moment', 'client');

	api.addAssets([
		'dist/fullcalendar.js',
		'dist/fullcalendar.css',
		'dist/lang/nl.js',
	], 'client');
	api.addFiles('inject.js', 'server');
});
