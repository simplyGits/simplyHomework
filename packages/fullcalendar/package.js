Package.describe({
	name: 'simply:fullcalendar',
	version: '2.4.0',
	summary: 'vanilla fullcalendar packaged for Meteor.',
	git: '',
	documentation: 'README.md',
});

Package.onUse(function(api) {
	api.versionsFrom('1.1.0.3');
	api.use('momentjs:moment', 'client');
	api.addFiles([
		'fullcalendar/dist/fullcalendar.js',
		'fullcalendar/dist/fullcalendar.css',
		'fullcalendar/dist/lang/nl.js',
	], 'client');
});
