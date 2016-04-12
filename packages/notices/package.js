Package.describe({
	name: 'simply:notices',
	version: '0.0.1',
	summary: 'swagger notices everywhere.',
	git: '',
	documentation: 'README.md',
});

Npm.depends({
	'simplyemail': '1.0.2',
});

Package.onUse(function(api) {
	api.versionsFrom('1.2.1');
	api.use([
		'coffeescript',
		'check',
		'stevezhu:lodash@3.10.1',
		'mongo',
		'modules',
	]);
	api.use([
		'tracker',
		'reactive-var',
		'templating',
		'mquandalle:stylus',
		'handlebars',
		'schedule-functions',
		'meteorhacks:subs-manager',
		'ms',
	], 'client');
	api.use([
		'email',
		'emails',
		'ecmascript',
		'percolate:synced-cron',
		'simply:external-services-connector',
		// 'reywood:publish-composite',
	], 'server');

	api.addFiles([
		'lib/collections.coffee',
		'lib/schemas.coffee',
		'lib/methods.coffee',
	]);
	api.addFiles([
		'client/noticesManager.coffee',
		'client/notices.html',
		'client/notices.styl',
		'client/notices.coffee',

		'client/recentGrades/recentGrades.html',
		'client/recentGrades/recentGrades.styl',
		'client/recentGrades/recentGrades.coffee',

		'client/tasks/tasks.html',
		'client/tasks/tasks.styl',
		'client/tasks/tasks.coffee',

		'client/lessons/currentLesson.html',
		'client/lessons/currentLesson.coffee',
		'client/lessons/nextlesson.html',
		'client/lessons/nextlesson.coffee',
		'client/lessons/lessonsOverview.html',
		'client/lessons/lessonsOverview.styl',
		'client/lessons/lessonsOverview.coffee',

		'client/scrappedHours/scrappedHours.html',
		'client/scrappedHours/scrappedHours.styl',
		'client/scrappedHours/scrappedHours.coffee',

		'client/changedHours/changedHours.html',
		'client/changedHours/changedHours.styl',
		'client/changedHours/changedHours.coffee',

		'client/tests/tests.html',
		'client/tests/tests.styl',
		'client/tests/tests.coffee',

		'client/studyUtils/studyUtils.html',
		'client/studyUtils/studyUtils.styl',
		'client/studyUtils/studyUtils.coffee',

		'client/birthday/birthday.html',
		'client/birthday/birthday.styl',
		'client/birthday/birthday.coffee',

		'client/messages/messages.html',
		'client/messages/messages.styl',
		'client/messages/messages.coffee',

		'client/sick/sick.coffee',

		'client/projects/projects.html',
		'client/projects/projects.styl',
		'client/projects/projects.coffee',
	], 'client');
	api.addFiles([
		'server/emails.js',
	], 'server');

	api.export([
		'NoticeManager',
		'Notifications',
	]);
	api.export([
		'NoticeMails',
	], 'server');
});
