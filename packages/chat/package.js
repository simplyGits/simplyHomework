Package.describe({
	name: 'chat',
	version: '0.0.1',
	summary: 'Some awesome chat yo.',
	git: '',
	documentation: 'README.md',
});

Package.onUse(function(api) {
	api.versionsFrom('1.2.1');

	api.use('public-api', { weak: true }); // for irc bridge and websocket bridge 'n tuff.
	api.use('aldeed:collection2', { weak: true });
	api.use([
		'coffeescript',
		'check',
		'tmeasday:publish-counts',
		'stevezhu:lodash',
		'mongo',
	]);
	api.use([
		'templating',
		'handlebars',
		'mquandalle:stylus',
		'reactive-var',
		'simply:reactive-local-storage',
	], 'client');
	api.use([
		'reywood:publish-composite',
	], 'server');

	api.addFiles([
		'lib/chatRoom.coffee',
		'lib/chatMessage.coffee',
		'lib/middlewares.coffee',
		'lib/collections.coffee',
		'lib/schemas.coffee',
		'lib/methods.coffee',
	]);
	api.addFiles([
		'client/chatSidebar.html',
		'client/chatSidebar.styl',
		'client/chatSidebar.coffee',
		'client/fullscreenChatWindow.html',
		'client/fullscreenChatWindow.styl',
		'client/fullscreenChatWindow.coffee',
		'client/mobileChatWindow.html',
		'client/mobileChatWindow.styl',
		'client/mobileChatWindow.coffee',
		'client/chatMessages.html',
		'client/chatMessages.coffee',
	], 'client');
	api.addFiles([
		'server/_startup.coffee',
		'server/security.coffee',
		'server/publish.coffee',
	], 'server');

	api.export([
		'ChatRoom',
		'ChatMessage',
		'ChatRooms',
		'ChatMessages',
	]);
});