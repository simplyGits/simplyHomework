if (!Meteor.settings.public.onesignal) {
	console.warn('`settings.public.onesignal` is null or undefined, onesignal package will be disabled.');
} else if (Meteor.isClient) {
	require('./client.js');
} else if (Meteor.isServer) {
	require('./server.js');
}
